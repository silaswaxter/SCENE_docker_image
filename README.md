```
__/\\\\\\\\\\\__________/\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\________
_/\\\/////////\\\_____/\\\////////__\/\\\///////////__\/\\\\\\___\/\\\_\/\\\///////////________
_\//\\\______\///____/\\\/___________\/\\\_____________\/\\\/\\\__\/\\\_\/\\\__________________
___\////\\\__________/\\\_____________\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\_________
_______\////\\\______\/\\\_____________\/\\\///////______\/\\\\//\\\\/\\\_\/\\\///////_________
___________\////\\\___\//\\\____________\/\\\_____________\/\\\_\//\\\/\\\_\/\\\_______________
_____/\\\______\//\\\___\///\\\__________\/\\\_____________\/\\\__\//\\\\\\_\/\\\______________
_____\///\\\\\\\\\\\/______\////\\\\\\\\\_\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\\\\\\\\\\\\\_
________\///////////___________\/////////__\///////////////__\///_____\/////__\///////////////_
```
# Standard Custom Extendable Integrated Environment
The goal of this project is to create a standard development environment using docker.  Code
created with this targets arm microcontrollers;  toolchain is the gcc-arm-none-eabi (C/C++ and 
distributed by arm).  

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

## Container Entrypoint Script
**TL;DR the entry script runs whenever the docker container is run.**

### Purpose of Script
The purpose of the script came from the need to add the toolchain to the $PATH enviornment 
variable.  The toolchain path varries depending on version because the folder name of the toolchain
is version specific.  The entrypoint script solves this by searching for the folder with a regex
and adding the binary path to the $PATH enviornment variable.

## Future Plans
- Slim down unnecesary parts of the toolchain

## Workflow
- Attempting to use Trunk-Based Workflow (https://trunkbaseddevelopment.com)
- Attempting to adhere to Semantic Versioning
