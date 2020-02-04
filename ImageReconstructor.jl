# Add as many threads as possible
#=
if length(procs()) < Sys.CPU_THREADS
    addprocs(Sys.CPU_THREADS - length(procs()))
end
# Activate environment and download required packages.
@everywhere using Pkg
@everywhere Pkg.activate(@__DIR__)
# Anything with @everywhere will be availible to every thread
# Apply imports to all threads
=#
using Pkg
Pkg.activate(@__DIR__)
include("Reconstruction.jl")
using SharedArrays, Statistics, FileIO

# Constants
const imageFile = "img.jpg"
const stencilWidth = 40
const stencilHeight = 40
const stencilDirectory = "ssbM"

# These are both SharedArrays so are shared between all processes
# img contains the pixel data of the ground truth
const img = Reconstruction.loadImage(imageFile, "stencil")
# result is completely black right now but will be the reconstructed image
result = similar(img)

# Since I'm bad at Julia these are reconstructed for evey thread so there's probably
# a lot of file reading on startup. I haven't bothered fixing it as it probably doesn't affect
# performance during iteration. Maybe some CPU cache optimizations could be found if there is a way to share all
# stencils between processes.
const stencilData = [Reconstruction.loadImage(string(stencilDirectory, "/", file), "stencil") for file in readdir(stencilDirectory) if occursin(r"\.(gif|jpe?g|png)$", file)]
# Turn stencils into a list of tuples having 3 values
# 1. The color data of the stencil
# 2. The opacity data of the stencil
# 3. The average color of the stencil
#
# This can probably be made better by using structs or something.

const stencils = 
[
    Reconstruction.Stencil(
        stencil[:,:,1:3], 
        repeat(convert(Array{Float64}, stencil[:,:,4] / 255), outer = (1, 1, 3)), 
        reshape([
            Statistics.mean(stencil[:,:,1][stencil[:,:,4] .== 255])
            Statistics.mean(stencil[:,:,2][stencil[:,:,4] .== 255])
            Statistics.mean(stencil[:,:,3][stencil[:,:,4] .== 255])
        ], 1, 1, 3)
    ) 
    for stencil in stencilData
];


println("Initial filling of the image to remove gaps, can take a long time")
@time Reconstruction.initialfill(img, result, stencils, stencilHeight, stencilWidth)
println("starting random reconstruction of the image")
Reconstruction.genImage(img, result, stencils, stencilHeight, stencilWidth)
save("result.png", Reconstruction.to_img(result))
