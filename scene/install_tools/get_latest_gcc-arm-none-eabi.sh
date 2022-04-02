#!/bin/bash
##########
# DESC:
#	Downloads the HTML from the official ARM Download page;  parses for latest version and 
#	release date.  Then, it checks in the output dir for a local toolchain file.  Next, it compares
#	the local toolchain's filesize to the remote toolchain's filesize.  If the local toolchain does
#	not exist or is not within tolerance, the remote toolchain is downloaded to the output dir.
# NOTES:
# AUTHOR:   Silas Waxter (silaswaxter@gmail.com)
# DATE:		03/09/2022
##########

#####
# Definitions
#####
# Absolute path to this script,    (eg /home/silas/bin/foo.sh)
SCRIPT_NAME=$(readlink -f "$0")
# Absolute path this script is in, (eg /home/silas/bin)
SCRIPT_DIR=$(dirname "${SCRIPT_NAME}")


# +/- Tolerance of Remote Toolchain Filesize (as fraction)
declare -i NUMERATOR DENOMINATOR  #set integer attribute
NUMERATOR="1"
DENOMINATOR="50"

# Where to save temp files and the toolchain
OUTPUT_DIR="/opt/gcc-arm-none-eabi"

flag_SILENT="false"
flag_NAME_ONLY="false"

#####
# Includes
#####
. ${SCRIPT_DIR}/curl_functions.sh

#####
# Parse Passed Flags
#####
while test $# -gt 0; do
	case "$1" in
		-h|--help)
			echo "USAGE:    get_latest_gcc-arm-none-eabi.sh [options]"
			echo "ABOUT:    tool for downloading toolchain from ARM official downloads and"
	  		echo "          retrieving latest version"
      		echo " "
      		echo "OPTIONS:"
      		echo "-h, --help                Show help"
      		echo "-o,                       Output directory for toolchain and temp html files"
			echo "-s,                       Execute silently"
      		echo "--name-only,              Search for latest toolchain and print where it should"
      		echo "                          be installed;  do NOT download."
			echo " "
      		exit 0
      		;;
    	-s)
	  		flag_SILENT="true"
			shift
      		;;
    	-o)
      		shift
      		if test $# -gt 0; then
        		export OUTPUT_DIR=$1
      		else
        		echo "no output dir specified"
        		exit 1
      		fi
      		shift
      		;;
    	--name-only)
	  		flag_SILENT="true"
	  		flag_NAME_ONLY="true"
			shift
      		;;
    	*)
      		break
      		;;
	esac
done

# FUNCTION:	only prints when flag_SILENT == false
# ARG1:		the message to print
inform () {
	if test "$flag_SILENT" = "false"; then
		echo -e "$1"
	fi
}

# FUNCTION:	gets filesize of toolchain file in directory
# ARG1:		name of directory (no spaces)
# ARG2:		name of file (no spaces)
get_local_toolchain_filesize () {
	ls -s "$1" | grep "$2$" | awk '{print $1}'
}

# FUNCTION:	gets filesize of toolchain at download url provided
# ARG1:		fileURL
get_remote_toolchain_filesize () {
	curl -sIL $1 | grep -i "content-length:" | awk '{print $2/1024}' | tail -n 1
}

# FUNCTION:	checks if the local toolchain filesize is whithin tolerance of remote's
# ARG1:		local toolchain filesize
# ARG2:		remote toolchain filesize
# RETURN:	1 if true; 0 if false.
is_local_toolchain_fs_within_tolerance () {
	declare -i DELTA UPPERBOUND LOWERBOUND   # set integer attribute
	DELTA=$(expr $(expr $2 \* $NUMERATOR) / $DENOMINATOR)
	UPPERBOUND=$(expr $2 + $DELTA)
	LOWERBOUND=$(expr $2 - $DELTA)

	if test "$1" -le "$UPPERBOUND"; then
		if test "$1" -ge "$LOWERBOUND"; then
			echo 1
			return 1
		else
			echo 0
			return 0
		fi
	fi
}


#####
# Ensure Output Directory Exists
#####
mkdir -p $OUTPUT_DIR

#####
# Retrieve Download Page
####
DOWNLOADS_PAGE_URL="https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads"
DOWNLOADS_PAGE_FILE="$OUTPUT_DIR/toolchain_download_page.html"

inform "Retreiving Arm Downloads Page..."
download_with_curl "$DOWNLOADS_PAGE_FILE" "$DOWNLOADS_PAGE_URL" "-s"


#####
# Parse Download Page (for latest version and release date)
#####
PARSE_SED_REGEX="^\s*Arm GNU Toolchain: (\S*[^\r\n]) <.+?>(.+?)<\/span>"

inform "Parsing for Latest Version Info..."
LATEST_VERSION=$(sed -nE "s/$PARSE_SED_REGEX/\1/p" $DOWNLOADS_PAGE_FILE | tr -d '\r')
VERSION_DATE=$(sed -nE "s/$PARSE_SED_REGEX/\2/p" $DOWNLOADS_PAGE_FILE | tr -d '\r')
inform "\t latest version:\t $LATEST_VERSION"
inform "\t released:\t\t $VERSION_DATE\n"

# no longer need download page file
rm $DOWNLOADS_PAGE_FILE

#####
# Pass Toolchain Filename to Parent via File
#####
TOOLCHAIN_FILE="$OUTPUT_DIR/gcc-arm-none-eabi-$LATEST_VERSION.tar.xz"

if test "$flag_NAME_ONLY" = "true"; then
	echo "$TOOLCHAIN_FILE"
	exit 0
fi


#####
# Should Download Toolchain?
#####
TOOLCHAIN_DOWNLOAD_URL="https://developer.arm.com/-/media/Files/downloads/gnu/$LATEST_VERSION/binrel/gcc-arm-$LATEST_VERSION-x86_64-arm-none-eabi.tar.xz"

inform "Searching for Latest Toolchain... \"$TOOLCHAIN_FILE\""
if test -e "$TOOLCHAIN_FILE"; then
	inform "\t local toolchain file found."
	inform "\t Comparing Filesize Local vs Remote..."
	LOCAL_TOOLCHAIN_FS=$(get_local_toolchain_filesize "$TOOLCHAIN_FILE")
	REMOTE_TOOLCHAIN_FS=$(get_remote_toolchain_filesize "$TOOLCHAIN_DOWNLOAD_URL")
	inform "\t\t local filesize:  $LOCAL_TOOLCHAIN_FS KB"
	inform "\t\t remote filesize:  $REMOTE_TOOLCHAIN_FS KB"
	IS_LOCAL_FS_GOOD=$(is_local_toolchain_fs_within_tolerance "$LOCAL_TOOLCHAIN_FS" "$REMOTE_TOOLCHAIN_FS")
	if test "$IS_LOCAL_FS_GOOD" == "1"; then
		inform "\t\t local toolchain within tolerance."
		inform "\t\t Exiting..."
		exit 0
	else
		inform "\t\t local toolchain NOT within tolerance."
		inform "\t\t Renaming Local Toolchain File..."
		mv "$TOOLCHAIN_FILE" "$TOOLCHAIN_FILE.moved_by_arm_script"
	fi
else
	inform "\t local toolchain NOT found."
fi
inform "\n"


#####
# Downloading Toolchain
#####
inform "Downloading Toolchain..."
download_with_curl "$TOOLCHAIN_FILE" "$TOOLCHAIN_DOWNLOAD_URL"

#####
# End of Script
#####
inform "Exiting..."
exit 0
