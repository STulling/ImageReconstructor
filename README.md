# Image Reconstructor
> Reconstructs images using other images

This program turns an ordinary image and one or multiple stencils into an image created solely with those stencils. 

![](header.png)

## Installation

Any OS I guess:

Install [Julia](https://julialang.org/)
Install packages:
* Images
* FileIO
* Colors
* ImageCore
* SharedArrays 
* Statistics
* Random

Some of these are already included in Julia but idk which ones.
My advice is just running the script and see what's wrong

If everything is set up, just edit some constants in ImageReconstructor.jl and run it

```sh
julia ImageReconstructor.jl
```

## Usage example

Add a stencil folder and an image to reconstruct.
Then point the script to those files.
And run it.

There is some code at the bottom to use with video.
You can probably figure it out yourself.

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

* 0.0.1 "Works on my machine" Edition
  * Initial shitty script

## Contributors

Simon Tulling – simon.tulling99@gmail.com – u/JanDoedelGaming
