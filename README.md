# Image Reconstructor
> Reconstructs images using other images

This program turns an ordinary image and one or multiple stencils into an image created solely with those stencils. 

![](header.png)

## Installation

Any OS I guess:

Install [Julia](https://julialang.org/)

Instantiate the project environment:
```sh
julia --project=@. -e "using Pkg; Pkg.instantiate()"
```

If everything is set up, you can run the following in the command line.

```sh
julia ImageReconstructor.jl -i america.bmp -s stencils -r america_reconstructed.png
```
* `-i` is for the image location (png, jpg, jpeg, and gif file formats accepted)
* `-s` is for the stencils folder location
* `-r` is for the result image location (_optional_)


## Usage example

The project includes a sample image and some sample stencils, in the `stencils` folder.

![](america.bmp)

![](stencils/red.bmp)
![](stencils/white.bmp)
![](stencils/blue.bmp)

There is some commented-out code for video applications included at the bottom of the file. This is untested/in need of further refinement.

## Contributing

There's a lot of work that can be put into this program, I will list some stuff that would be great if implemented.
Any other stuff is also cool.

* GUI
* CLI
* Support for stencils of differing sizes
* Speed up are always great
* Better video support
* Live preview?
* Fixing bugs (all threads loading stencils)

## Release History
* 0.0.2 "Works on other machines" Edition
  * Actual project environment thanks to Vexatos
  * Automatic adjustment of max threads thanks to zachmatson
  * Opacity is now scaled instead of binary
* 0.0.1 "Works on my machine" Edition
  * Initial shitty script

## Contributors

Simon Tulling – simon.tulling99@gmail.com – u/JanDoedelGaming

Don't hesitate to contact me or make an issue for any issues with the code.
