using Pkg
Pkg.activate(@__DIR__)
using ImageReconstructor
println("Loading Static Interface...")
reconstructionArguments = ImageReconstructor.ReconstructionArguments(
    "america.bmp",
    "stencils",
    "result.png",
    10_000,
    false
)
println("Loaded Static Interface")
println("Starting ImageReconstructor...")
ImageReconstructor.reconstructImage(reconstructionArguments)
