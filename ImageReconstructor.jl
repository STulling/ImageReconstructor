using Distributed
# Add threads, since my PC has 16 threads I add 15 to the current thread to get 16 total threads
addprocs(15)
# Anything with @everywhere will be availible to every thread
# Apply imports to all threads
@everywhere using Images, FileIO, Colors, ImageCore, SharedArrays, Statistics, Random

# Loads an Image into either an array or SharedArray, could be cleaned up
@everywhere function loadImage(file, type)
    tmp = permuteddimsview(rawview(channelview(load(file))), (2,3,1))
    if (type == "stencil")
        return tmp
    else
        result = SharedArray{Int64}(size(tmp))
        result[:] = tmp[:]
        return result
    end
end

# Turns an array into an image
function to_img(array)
    colorview(RGB, Float64.(permuteddimsview(array, (3,1,2)))./255)
end

# Calculates the mean squared distance.
# Other distances can be tried out but this seemed the best.
# You can also not include the division but in this case I like it more since
# this keeps the error kinda normalized between images of differing sizes.
# Removing the division likely speeds up the iteration.
@everywhere msd(a::AbstractArray{T}, b::AbstractArray{T}) where {T<:Number} = abs2(a - b) / length(a);

# These are both SharedArrays so are shared between all processes
# img contains the pixel data of the ground truth
img = loadImage("melee.png", "image")
# result is completely black right now but will be the reconstructed image
result = SharedArray{Int64}(size(img));

# Since I'm bad at Julia these are reconstructed for evey thread so there's probably
# a lot of file reading on startup. I haven't bothered fixing it as it probably doesn't affect
# performance during iteration. Maybe some CPU cache optimizations could be found if there is a way to share all
# stencils between processes.
@everywhere stencilWidth = 64
@everywhere stencilHeight = 64
@everywhere stencilDirectory = "stencils2"
@everywhere stencilData = [loadImage(string(stencilDirectory, "/", file), "stencil") for file in readdir(stencilDirectory)]
# Turn stencils into a list of tuples having 3 values
# 1. The color data of the stencil
# 2. The opacity data of the stencil
# 3. The average color of the stencil
#
# This can probably be made better by using structs or something.
@everywhere stencils = 
[
    (
        stencil[:,:,1:3], 
        repeat(convert(Array{Int64}, stencil[:,:,4] / 255), outer = (1, 1, 3)), 
        reshape([
            Statistics.mean(stencil[:,:,1][stencil[:,:,4] .== 255])
            Statistics.mean(stencil[:,:,2][stencil[:,:,4] .== 255])
            Statistics.mean(stencil[:,:,3][stencil[:,:,4] .== 255])
        ], 1, 1, 3)
    ) 
    for stencil in stencilData
];

# Chooses the optimal stencil based on a given target average color.
# Maybe there's a better way to do this but it's fine imo
@everywhere function choose(target, stencils)
    if length(stencils) > 1
        best = 9999
        bestStencil = nothing
        for stencil in stencils
            this = msd(stencil[3], target)
            if this < best
                best = this
                bestStencil = stencil
            end
        end
        return bestStencil
    end
    return stencils[0]
end

# Gets the average color, not much to it.
@everywhere function getAverageColor(image, x1, y1, x2, y2)
    Statistics.mean(image[x1:x2, y1:y2, :], dims=(1,2))
end

# Gets a random position and a corresponding stencil.
@everywhere function getStencil()
    pos = mod.(rand(Int64, 2), [size(img)[1] - stencilWidth, size(img)[2] - stencilHeight]) + [1; 1]
    pos2 = pos + [stencilWidth-1; stencilHeight-1]
    target = getAverageColor(img, pos[1], pos[2], pos2[1], pos2[2])
    stencil = choose(target, stencils)
    return pos, pos2, stencil[2], stencil[1]
end

# Gets a stencil based on the input coordinates
@everywhere function getStencil(x, y)
    pos = [x, y]
    pos2 = pos + [stencilWidth-1; stencilHeight-1]
    target = getAverageColor(img, pos[1], pos[2], pos2[1], pos2[2])
    stencil = choose(target, stencils)
    return stencil[2], stencil[1]
end

# Recreates the images
function genImage()
    # @sync makes sure the program will only continue once all theads are done.
    # @distibuted makes the for loop run on all threads
    @sync @distributed for i in 1:16000000
        # Get a random position and stencil
        (pos, pos2, opacity, pixels) = getStencil()
        # Apply the stencil to a temporarily
        tmpresult = result[pos[1]:pos2[1], pos[2]:pos2[2], :] .* (1 .- opacity) .+ opacity .* pixels
        # Check the old distance on that position of the image
        distance_old = msd(img[pos[1]:pos2[1], pos[2]:pos2[2], :], result[pos[1]:pos2[1], pos[2]:pos2[2], :])
        # Check the new distance on that position of the image
        distance_new = msd(img[pos[1]:pos2[1], pos[2]:pos2[2], :], tmpresult)
        # If it improved then save it
        if distance_old > distance_new
            result[pos[1]:pos2[1], pos[2]:pos2[2], :] = tmpresult
        end
        # Print some stuff during the loop
        if i % 100000 == 0
            error = msd(img, result)
            println(error)
        end
    end
end

# Fills the image with some stencils
function initialfill()
    # @sync makes sure the program will only continue once all theads are done.
    # @distibuted makes the for loop run on all threads
    # for all x
    @sync @distributed for i in shuffle(1:size(img, 1)-stencilWidth)
        # for all y
        for j in shuffle(1:size(img, 2)-stencilHeight)
            # Get the stenicl that corresponds to that location
            (opacity, pixels) = getStencil(i, j)
            # Just add it, no checking for improvements
            result[i:i+stencilWidth-1, j:j+stencilHeight-1, :] = result[i:i+stencilWidth-1, j:j+stencilHeight-1, :] .* (1 .- opacity) .+ opacity .* pixels
        end
    end
end

println("Initial filling of the image to remove gaps, can take a long time")
initialfill()
println("starting random reconstruction of the image")
genImage()
save("result.png", to_img(result))

#= Use in case you want to use video
for i in 1:length(readdir("Images"))
    img[:] = loadImage(string("Images/frame_", i, ".jpg"), "stencil")[:]
    println(string("starting generation of image ", i))
    genImage()
    save(string("Results/frame_", i, ".jpg"), imgshow(result))
end
=#