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
# Absolute path of this script
SCRIPT_FILE=$(readlink -f "${0}")
# Absolute path to this script's directory
SCRIPT_DIR=$(dirname "${SCRIPT_FILE}")


# Tolerance between local and remote toolchain filesize (as fractional percent)
declare -i TOOLCHAIN_SIZE_TOLERANCE_NUMERATOR TOOLCHAIN_SIZE_TOLERANCE_DENOMINATOR
TOOLCHAIN_SIZE_TOLERANCE_NUMERATOR="1"
TOOLCHAIN_SIZE_TOLERANCE_DENOMINATOR="50"

# Where to save temp files and the toolchain
OUTPUT_DIR="/opt/gcc-arm-none-eabi"

SILENT_EXECUTION="false"
FETCH_NAME_ONLY_EXECUTION="false"

#####
# Includes
#####
. ${SCRIPT_DIR}/curl_functions.sh

#####
# Parse Passed Flags
#####
while test ${#} -gt 0; do
	case "${1}" in
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
	  		SILENT_EXECUTION="true"
			shift
      		;;
    	-o)
      		shift
      		if test ${#} -gt 0; then
        		export OUTPUT_DIR=${1}
      		else
        		echo "no output dir specified"
        		exit 1
      		fi
      		shift
      		;;
    	--name-only)
	  		SILENT_EXECUTION="true"
	  		FETCH_NAME_ONLY_EXECUTION="true"
			shift
      		;;
    	*)
      		break
      		;;
	esac
done

# FUNCTION:	conditionally print based on SILENT_EXECUTION flag
# ARG1:		the message to print
inform () {
	if test "${SILENT_EXECUTION}" = "false"; then
		echo -e "${1}"
	fi
}

# FUNCTION:	gets filesize of toolchain file in directory
# ARG1:		name of directory (no spaces)
# ARG2:		name of file (no spaces)
get_local_toolchain_filesize () {
	ls -s "${1}" | grep "${2}$" | awk '{print $1}'
}

# FUNCTION:	gets filesize of toolchain at the provided download url
# ARG1:		toolchain download url
get_remote_toolchain_filesize () {
	curl -sIL ${1} | grep -i "content-length:" | awk '{print $2/1024}' | tail -n 1
}

# FUNCTION:	checks that the local toolchain filesize is within tolerance of remote's filesize
# ARG1:		local toolchain filesize
# ARG2:		remote toolchain filesize
# RETURN:	1 if true; 0 if false.
is_local_toolchain_within_tolerance () {
	declare -i DELTA UPPERBOUND LOWERBOUND   # set integer attribute
	DELTA=$(expr $(expr ${2} \* ${TOOLCHAIN_SIZE_TOLERANCE_NUMERATOR}) / ${TOOLCHAIN_SIZE_TOLERANCE_DENOMINATOR})
	UPPERBOUND=$(expr ${2} + ${DELTA})
	LOWERBOUND=$(expr ${2} - ${DELTA})

	if test "${1}" -le "${UPPERBOUND}"; then
		if test "${1}" -ge "${LOWERBOUND}"; then
			echo 1
			return 1
		else
			echo 0
			return 0
		fi
	fi
}


# Ensure Output Directory Exists
mkdir -p ${OUTPUT_DIR}

# Retrieve Download Page
DOWNLOADS_PAGE_URL="https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
DOWNLOADS_PAGE_FILE="${OUTPUT_DIR}/toolchain_download_page.html"
inform "Retrieving Arm Downloads Page..."
download_with_curl "${DOWNLOADS_PAGE_FILE}" "${DOWNLOADS_PAGE_URL}" "-s"


# Parse Download Page (for version and release date)
inform "Parsing for Latest Toolchain Info..."
LATEST_VERSION=$(sed -nE "s/.*>Version\W*(\d*.*)<.*/\1/p" ${DOWNLOADS_PAGE_FILE} | tr -d '\r')
VERSION_DATE=$(sed -nE "s/.*>Released\W*([A-Z]+[a-z]+.*)<.*/\1/p" ${DOWNLOADS_PAGE_FILE} | tr -d '\r')
inform "\t latest version:      ${LATEST_VERSION}"
inform "\t released:            ${VERSION_DATE}\n"
rm ${DOWNLOADS_PAGE_FILE}

TOOLCHAIN_DOWNLOAD_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${LATEST_VERSION}/binrel/gcc-arm-${LATEST_VERSION}-x86_64-arm-none-eabi.tar.xz"
TOOLCHAIN_FILE="${OUTPUT_DIR}/gcc-arm-none-eabi-${LATEST_VERSION}.tar.xz"

if test "${FETCH_NAME_ONLY_EXECUTION}" = "true"; then
	echo "${TOOLCHAIN_FILE}"
	exit 0
fi

# Check if local toolchain is up-to-date
inform "Searching for Latest Toolchain at \"${TOOLCHAIN_FILE}\"..."
if test -e "${TOOLCHAIN_FILE}"; then
	inform "\t local toolchain file found."
	inform "\t comparing local vs remote file size..."
	LOCAL_TOOLCHAIN_SIZE=$(get_local_toolchain_filesize "${TOOLCHAIN_FILE}")
	REMOTE_TOOLCHAIN_SIZE=$(get_remote_toolchain_filesize "${TOOLCHAIN_DOWNLOAD_URL}")
	inform "\t\t local filesize:  ${LOCAL_TOOLCHAIN_SIZE} KB"
	inform "\t\t remote filesize:  ${REMOTE_TOOLCHAIN_SIZE} KB"
    
	if [ "$(is_local_toolchain_within_tolerance "${LOCAL_TOOLCHAIN_SIZE}" "${REMOTE_TOOLCHAIN_SIZE}")" -eq 1 ]; then
		inform "\t local toolchain within tolerance."
		exit 0
	else
		inform "\t local toolchain NOT within tolerance."
		inform "\t renaming local toolchain file..."
		mv "${TOOLCHAIN_FILE}" "${TOOLCHAIN_FILE}.moved_by_arm_script"
	fi
else
	inform "\t local toolchain NOT found."
fi

inform "\nDownloading Toolchain..."
download_with_curl "${TOOLCHAIN_FILE}" "${TOOLCHAIN_DOWNLOAD_URL}"

exit 0
