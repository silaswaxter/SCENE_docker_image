# Arm GCC Embedded Dev Docker
The goal of this project is to create a standard development environment using docker.  Code
created with this targets arm microcontrollers;  compiled using the gcc-arm-none-eabi toolchain 
(C/C++ and distributed by arm).  

## Toolchain gcc-arm-none-eabi
The toolchains packaged in many of the different linux repositories (arch, Ubunutu/Debian, alpine) 
were not up to date with the most recent release;  therefore, I created a shell script used to
download the tar file from Arm's official download page.
> It should be noted that Embedded version of Arm's toolchain is discontinued (no more updates).
> They merged the Embedded and A-profile (also discontinued) versions of the toolchain into a
> single toolchain.  This is **why the docker image for this project is so large** compared to some
> of the guides online about this topic.
### The Download Script
The shell script downloads the html of the download page and parses it for the latest version and
release date.  It looks in the output directory (where the toolchain will be installed) for an
existing toolchain.  If there is a toolchain there with the correct name that is basically the same 
size as the "remote" toolchain, the script will not download the "remote" toolchain. Run the script
with --help for some other options.

## Container Entrypoint Script Grossness
**TL;DR the entry script runs whenever the docker container is run.**

### Purpose of Script
The purpose of the script came from the need to add the path of the toolchain's binaries to the 
$PATH enviornment variable.  The toolchain path varries depending on version because the folder 
name of the toolchain includes version info.  Environemnt variables can be manipulated using the
ENV directive inside the dockerfile;  however, there is no way of passing the name of the folder
back to the toolchain and wildcards don't work.  The entrypoint script solves this by searching
for the folder with a regex and adding the binary path to the $PATH enviornment variable.

### Grossness
There is a (WET) code smell that's hard to address, but it only matters when changing entrypoint 
script name and/or location.  As previously hinted, the smell is from the hard-coding of
variable-contained information into the ENTRYPOINT directive.  This is due to a couple of
competing factors:

1. Variables are good.  They keep code DRY and make it easier to change stuff.
2. In Docker, the ENTRYPOINT directive executes before the CMD directive;  in fact, the CMD "stuff"
is directly appended ENTRYPOINT "stuff".
3. Within the ENTRYPOINT directive, environment variables are not evaluated directly.  In order to
do so, one must have the ENTRYPOINT run `/bin/sh -c "some stuff with variables"`.

So, in order to evaluate the variables (ie entrypoint script name and location) inside the
ENTRYPOINT directive, the default command must be /bin/sh.  However, when the script is run through
/bin/sh, the CMD "stuff" is no longer arguments to the script--they are arguments to /bin/sh.
The current solution is to hardcode the entrypoint script path inside the
ENTRYPOINT directive and supply big warning comments around the entrypoint variable declarations.
Its awful and gross, but it works.

## Future Plans
- Slim down unnecesary parts of the toolchain
