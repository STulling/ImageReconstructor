# Image Reconstructor
> Reconstructs images using other images

This program turns an ordinary image and one or multiple stencils into an image created solely with those stencils.

![](header.png)

## Installation

CURRENT COMMIT IS BROKEN USE PREVIOUS COMMIT

Any OS I guess:

Install [Julia](https://julialang.org/)

In order to use multithreading (HIGHLY recommended), set the environment variable:
```sh
set JULIA_NUM_THREADS=x
```
Where x is the amount of threads that you can use. For most computers it's double the amount of cores. So a 4 core processor can use 8 threads.


Launch the script from the command line.
```sh
julia CLI.jl -i america.bmp -s stencils -r america_reconstructed.png
```
* `-i` is for the image location (png, jpg, jpeg, and gif file formats accepted)
* `-s` is for the stencils folder location
* `-r` is for the result image location (_optional, defaults to `result.png`_)

Or use:
```sh
julia StaticInterface.jl
```
Where you need to edit the file to present all folders and options.

## Usage example

The project includes a sample image and some sample stencils, in the `stencils` folder.

![](america.bmp)

![](stencils/red.bmp)
![](stencils/white.bmp)
![](stencils/blue.bmp)

If everything is configured correctly, you should see the following image:

![](result.png)

There is some commented-out code for video applications included at the bottom of the file. This is untested/in need of further refinement.

## Contributing

There's a lot of work that can be put into this program, I will list some stuff that would be great if implemented.
Any other stuff is also cool.

* GUI
* ~~CLI~~
* Support for stencils of differing sizes
* Speed up are always great
* Better video support
* Live preview?
* Fixing bugs (all threads loading stencils)

## Release History
* 0.1.0 "Might have broken everything for the sake of speed" Edition
  * Optimized everything for speed
  * It now uses a module (Julia pls make this less painful)
* 0.0.2 "Works on other machines" Edition
  * Actual project environment thanks to Vexatos
  * Automatic adjustment of max threads thanks to zachmatson
  * Opacity is now scaled instead of binary
* 0.0.1 "Works on my machine" Edition
  * Initial shitty script

## Contributors

Simon Tulling – simon.tulling99@gmail.com – u/JanDoedelGaming

Don't hesitate to contact me or make an issue for any issues with the code.
