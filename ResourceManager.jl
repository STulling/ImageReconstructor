using Images, FileIO, ImageFiltering
include("ReconstructionArguments.jl")

struct Stencil
    color::Array{UInt8,3}
    invertedOpacity::Array{UInt16,2}
    average::Array{Float64,1}
end

struct ResourceData
    groundTruth::Array{UInt8,3}
    averageImage::Array{Float64,3}
    result::Array{UInt8,3}
    stencils::Array{Stencil,1}
    stencilWidth::Int64
    stencilHeight::Int64
    iterations::Int64
    improve::Bool
end

# Loads an Image into the proper format
function loadImage(file::String)
    return permuteddimsview(rawview(channelview(load(file))), (2, 3, 1))
end

# Loads a Stencil into the proper format
function loadStencil(file)
    tmp = permuteddimsview(rawview(channelview(load(file))), (2, 3, 1))
    if size(tmp)[3] == 3
        return cat(
            dims = 3,
            tmp,
            convert(Array{UInt8}, 255 * ones(size(tmp)[1:2])),
        )
    end
    return tmp
end

function convertReadable(image)
    permuteddimsview(rawview(channelview(image)), (2, 3, 1))
end

function calcAverageImage(image, offset)::Array{Float64,3}
    filter = 3
    offsetx = offset[1] ÷ 2
    offsety = offset[2] ÷ 2
    gauss_filter = Kernel.gaussian(filter)
    offset_filter = reshape(
        gauss_filter,
        offsetx:offsetx+size(gauss_filter, 1)-1,
        offsety:offsety+size(gauss_filter, 1)-1,
    )
    convert(
        Array{Float64,3},
        convertReadable(imfilter(image, offset_filter)) .* 255,
    )
end

function getData(args::ReconstructionArguments)::ResourceData
    println("Loading image...")
    image = load(args.inputFile)
    groundTruth = convertReadable(image)[:, :, 1:3]
    println(size(groundTruth))
    println("Loaded image")
    println("Loading stencils...")
    stencils = loadStencils(args.stencilFolder)
    println("Loaded stencils")
    stencilWidth = size(stencils[1].color)[1]
    stencilHeight = size(stencils[1].color)[2]
    if (args.improve)
        result = loadImage(args.resultFile)
    else
        result = Array{UInt8}(undef, size(groundTruth))
    end
    println("Generating blurred image...")
    averageImage = calcAverageImage(image, size(stencils[1].color))
    println("Generated blurred image")
    return ResourceData(
        groundTruth,
        averageImage,
        result,
        stencils,
        stencilWidth,
        stencilHeight,
        args.iterations,
        args.improve
    )
end

function loadStencils(folderName::String)::Array{Stencil,1}
    result::Array{Stencil, 1} = Stencil[]
    i = 1
    pad = "                               "
    allfiles = readdir(folderName)
    for file in allfiles
        if !occursin(r"\.(jpe?g|png|bmp)$", file)
            print("Skipping: ", file, " (", i,"/", length(allfiles), ") " ,pad, "\r")
            i+=1
            continue
        end
        stencil::Array{UInt8, 3} = loadStencil(string(folderName, "/", file))
        pixels::Array{UInt8, 3} = round.(
            stencil[:, :, 1:3] .*
            repeat(stencil[:, :, 4] / 255, outer = (1, 1, 3)),
        )
        invertedOpacity::Array{UInt16, 2} = 255 .- stencil[:, :, 4]
        mean::Array{Float64, 1} = [
            Statistics.mean(stencil[:, :, 1][stencil[:, :, 4].==255])
            Statistics.mean(stencil[:, :, 2][stencil[:, :, 4].==255])
            Statistics.mean(stencil[:, :, 3][stencil[:, :, 4].==255])
        ]
        push!(result, Stencil(pixels, invertedOpacity, mean))
        print("Loaded: ", file, " (", i,"/", length(allfiles), ") " ,pad, "\r")
        i+=1
    end
    println()
    return result
end

# Turns an array into an image
function to_img(array)
    colorview(RGB, Float64.(permuteddimsview(array, (3, 1, 2))) ./ 255)
end

function saveResult(resultFile, result)
    save(resultFile, to_img(result))
end
