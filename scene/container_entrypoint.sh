#!/bin/sh
##########
# DESC:
#	Execute on container start.  
#	Append to $PATH
#		- appends toolchain/bin to path;  note that toolchain directory name will change with
#		  version and that by using this script these changes are irrelevant.
# NOTES:
# AUTHOR:   Silas Waxter (silaswaxter@gmail.com)
# DATE:		03/12/2022
##########

#####
# Update $PATH with toolchain binaries
#####
export PATH=${image_TOOLCHAIN_DIR}/$(eval ${GET_TOOLCHAIN_FILENAME})/bin:$PATH

#####
# Run the interactive shell
#####
"${@}"
