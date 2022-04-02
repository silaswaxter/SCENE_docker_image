#!/bin/bash
##########
# DESC:
#       Contains curl function(s) for retreiving files and html pages in a standard way;  can be
#       reused in multiple scripts.
# NOTES:
# AUTHOR:   Silas Waxter (silaswaxter@gmail.com)
# DATE:		03/26/2022
##########

# FUNCTION:	Downloads a file with curl
# ARG1:		output file name
# ARG2:		url to download from
# ARG3:		flags
download_with_curl () {
	if test "$3" == ""; then
		curl -fL -A "Chrome" -o "$1" "$2"
	else
		curl -fL -A "Chrome" -o "$1" "$3" "$2"
	fi

	#Error Handling
	if test "$?" == "0"; then
		inform "\t success.\n"

	else
		echo -e "\t curl command failed with: $?"
		echo -e "\t\t [TIP]: user running script needs read/write access to output dir"
		inform "\t exiting...\n"
		exit $?
	fi
}

