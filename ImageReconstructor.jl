include("ResourceManager.jl")

# Activate environment and download required packages.
using Pkg
Pkg.activate(@__DIR__)

# Import all necessary modules
using Colors
using Statistics
using Random
using StatsBase

mutable struct ThreadBuffer
    target::Array{Float64,1}
    stencil::Stencil
end

# Gets a stencil based on the input coordinates
function assignStencil!(
    x::Int64,
    y::Int64,
    data::ResourceData,
    stencilbuffer::Array{ThreadBuffer,1},
    n::Int64,
)::Nothing
    stencilbuffer[n].target[1] = data.averageImage[x, y, 1]
    stencilbuffer[n].target[2] = data.averageImage[x, y, 2]
    stencilbuffer[n].target[3] = data.averageImage[x, y, 3]
    best::Float64 = msd(data.stencils[1].average, stencilbuffer[n].target)
    stencilbuffer[n].stencil = data.stencils[1]
    len::Int64 = length(data.stencils)
    i::Int64 = 2
    while i::Int64 <= len
        stencil::Stencil = data.stencils[i]
        this::Float64 = msd(stencil.average, stencilbuffer[n].target)
        if this < best
            best = this
            stencilbuffer[n].stencil = stencil
        end
        i += 1
    end
    return
end


function msd2(a::Array{UInt8, 3}, b::Array{UInt8, 3}, xrange::UnitRange{Int64}, yrange::UnitRange{Int64}, zrange::UnitRange{Int64}, n::Int64)::Float64
    r::Int64 = 0
    for x in xrange
        for y in yrange
            for z in zrange
                @inbounds r += abs2(a[x, y, z] - b[x, y, z])
            end
        end
    end
    return r / n
end

function msd3(a::Array{UInt8, 3}, stencil::Array{UInt8, 3}, xrange::UnitRange{Int64}, yrange::UnitRange{Int64}, zrange::UnitRange{Int64}, n::Int64)::Float64
    r::Int64 = 0
    sx::Int64 = 1
    for x in xrange
        sy::Int64 = 1
        for y in yrange
            sz::Int64 = 1
            for z in zrange
                @inbounds r += abs2(a[x, y, z] - stencil[sx, sy, sz])
                sz+=1
            end
            sy+=1
        end
        sx+=1
    end
    return r / n
end


function genImage(data::ResourceData)::Nothing
    # Variables used in the calculations
    img::Array{UInt8,3} = data.groundTruth
    result::Array{UInt8,3} = data.result
    stencilWidth::Int64 = data.stencilWidth
    stencilHeight::Int64 = data.stencilHeight
    totalpixels::Int64 = stencilWidth * stencilHeight * 3

    # Variables necessary for workload
    width::Int64 = size(img, 1) - stencilWidth
    height::Int64 = size(img, 2) - stencilHeight
    thread_ops::Int64 = data.iterations ÷ Threads.nthreads()

    # Create and populate buffers for each thread
    stencilbuffer::Array{ThreadBuffer,1} = ThreadBuffer[]
    memorybuffer::Array{Array{UInt8,3}} = Array{Float64,3}[]
    for n = 1:Threads.nthreads()
        push!(
            stencilbuffer,
            ThreadBuffer(
                [0, 0, 0],
                data.stencils[1],
            ),
        )
        push!(memorybuffer, zeros(UInt8, size(data.stencils[1].color)))
    end
    zrange::UnitRange{Int64} = 1:3

    @time @inbounds Threads.@threads for n::Int64 = 1:Threads.nthreads()
        for _ = 1:thread_ops
            x::Int64 = rand(1:width)
            y::Int64 = rand(1:height)

            # Get the stencil that corresponds to that location
            assignStencil!(x, y, data, stencilbuffer, n)
            invertedOpacity = stencilbuffer[n].stencil.invertedOpacity
            pixels = stencilbuffer[n].stencil.color

            xrange::UnitRange{Int64} = x:x+stencilWidth-1
            yrange::UnitRange{Int64} = y:y+stencilHeight-1

            a::Int64 = 1
            for i::Int64 in xrange
                b::Int64 = 1
                for j::Int64 in yrange
                    memorybuffer[n][a, b, 1] =
                        (result[i, j, 1] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 1]
                    memorybuffer[n][a, b, 2] =
                        (result[i, j, 2] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 2]
                    memorybuffer[n][a, b, 3] =
                        (result[i, j, 3] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 3]
                    b += 1
                end
                a += 1
            end

            # Check the old distance on that position of the image
            distances1::Float64 =
                msd2(data.groundTruth, data.result, xrange, yrange, zrange, totalpixels)
            # Check the new distance on that position of the image
            distances2::Float64 =
                msd3(data.groundTruth, memorybuffer[n], xrange, yrange, zrange, totalpixels)
            # If it improved then save it
            if distances1 > distances2
                data.result[xrange, yrange, zrange] = memorybuffer[n]
            end
        end
    end
end

# Fills the image with some stencils
function initialfill(data::ResourceData)::Nothing
    # Variables used in the calculations
    img::Array{UInt8,3} = data.groundTruth
    result::Array{UInt8,3} = data.result
    stencilWidth::Int64 = data.stencilWidth
    stencilHeight::Int64 = data.stencilHeight

    # Variables necessary for workload
    width::Int64 = size(img, 1) - stencilWidth
    height::Int64 = size(img, 2) - stencilHeight
    numpositions::Int64 =
        (size(img, 1) * size(img, 2)) -
        (stencilHeight * size(img, 1) + stencilWidth * size(img, 2)) +
        stencilHeight * stencilWidth
    allpositions::Array{Int64,1} = shuffle(1:numpositions)
    thread_ops::Int64 = numpositions ÷ Threads.nthreads()

    # Create and populate buffers for each thread
    executionbuffer::Array{Array{Int64,1}} = Array{Int64,1}[]
    stencilbuffer::Array{ThreadBuffer} = ThreadBuffer[]
    for n = 1:Threads.nthreads()
        push!(
            executionbuffer,
            allpositions[(1+(n-1)*thread_ops):(n*thread_ops)],
        )
        push!(stencilbuffer, ThreadBuffer([0, 0, 0], data.stencils[1]))
    end

    GC.enable(false)
    @time @inbounds Threads.@threads for n::Int64 = 1:Threads.nthreads()
        for pos::Int64 in executionbuffer[n]
            x::Int64 = pos % width + 1
            y::Int64 = pos ÷ width + 1

            # Get the stencil that corresponds to that location
            assignStencil!(x, y, data, stencilbuffer, n)
            invertedOpacity = stencilbuffer[n].stencil.invertedOpacity
            pixels = stencilbuffer[n].stencil.color

            a::Int64 = 1
            for i::Int64 = x:x+stencilWidth-1
                b::Int64 = 1
                for j::Int64 = y:y+stencilHeight-1
                    result[i, j, 1] =
                        (result[i, j, 1] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 1]
                    result[i, j, 2] =
                        (result[i, j, 2] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 2]
                    result[i, j, 3] =
                        (result[i, j, 3] * invertedOpacity[a, b]) ÷ 255 +
                        pixels[a, b, 3]
                    b += 1
                end
                a += 1
            end
        end
    end
    GC.enable(true)
    return
end

function reconstructImage(args::ReconstructionArguments)::Nothing
    println("Loading all files...")
    resourceData::ResourceData = getData(args)
    println("Loaded all files")
    if (!resourceData.improve)
        println("Initial filling of the image to remove gaps, can take a long time")
        initialfill(resourceData)
    end
    println("starting random reconstruction of the image")
    genImage(resourceData)
    println("Saving result...")
    saveResult(args.resultFile, resourceData.result)
    println("Saved result!\n All Done")
end
