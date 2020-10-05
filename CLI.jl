using Pkg
Pkg.activate(@__DIR__)
include("ImageReconstructor.jl")
using ArgParse
s = ArgParseSettings()
@add_arg_table s begin
    "--image", "-i"
        help = "the path to the image file to reconstruct"
        required = true
    "--stencils-dir", "-s"
        help = "the path to the directory containing the stencils"
        required = true
    "--result", "-r"
        help = "the path to the reconstructed image file"
        default = "result.png"
        required = false
    "--iterations"
        help = "the number of iterations for placing random stencils"
        default = 1000
        arg_type = Int
        required = false
    "--improve"
        help = "Uses the result file and improves it"
        action = :store_true
end
args = parse_args(ARGS, s)
reconstructionArguments = ReconstructionArguments(
    args["image"],
    args["stencils-dir"],
    args["result"],
    args["iterations"],
    args["improve"]
)

reconstructImage(reconstructionArguments)
