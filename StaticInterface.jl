using Pkg
Pkg.activate(@__DIR__)
include("ImageReconstructor.jl")
println("Loading Static Interface...")
reconstructionArguments = ReconstructionArguments(
    "america.bmp",
    "stencils",
    "result.png",
    10_000,
    false
)
println("Loaded Static Interface")
println("Starting ImageReconstructor...")
reconstructImage(reconstructionArguments)
