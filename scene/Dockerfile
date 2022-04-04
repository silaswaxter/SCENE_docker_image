# Use Alpine with Glibc for the toolchain
FROM ubuntu:latest

#####
# Constants
#####
# GLOBAL
ENV TOOLCHAIN_SCRIPT_NAME="get_latest_gcc-arm-none-eabi.sh"
ENV ENTRYPOINT_SCRIPT_NAME="container_entrypoint.sh"
ENV USER_NAME="dev"

# BUILD CONSTANTS
ENV local_INSTALL_SCRIPTS_DIR="install_tools"
ENV local_DOT_FILES_DIR="container_dot_files"

# RESULTANT IMAGE CONSTANTS
ENV image_CUSTOM_PACKAGES_INSTALL_DIR="/opt"
ENV image_INSTALL_SCRIPTS_DIR="${image_CUSTOM_PACKAGES_INSTALL_DIR}/install_tools"
ENV image_TOOLCHAIN_DIR="${image_CUSTOM_PACKAGES_INSTALL_DIR}/gcc-arm-none-eabi"
ENV image_ENTRYPOINT_SCRIPT_DIR="/etc"

#####
# "Functions"
#####
# can use eval to resolve layered environment variables
ENV DOWNLOAD_TOOLCHAIN="${image_INSTALL_SCRIPTS_DIR}/${TOOLCHAIN_SCRIPT_NAME} \
                            -o ${image_TOOLCHAIN_DIR}"
ENV GET_TOOLCHAIN_FILENAME="${DOWNLOAD_TOOLCHAIN} --name-only"

#####
# IMAGE BUILD
#####
# Create Directories
#       not using WORKDIR b/c all paths are absolute; single RUN means only 1 layer instead of many
RUN mkdir -p \
    "${image_INSTALL_SCRIPTS_DIR}" \
    "${image_TOOLCHAIN_DIR}" \
    "${image_ENTRYPOINT_SCRIPT_DIR}"

# Copy install scripts, local packages (if they exist), and entrypoint script
COPY gcc-arm-none-eabi*tar.xz ${image_TOOLCHAIN_DIR}
COPY ${local_INSTALL_SCRIPTS_DIR} ${image_INSTALL_SCRIPTS_DIR}
COPY ${ENTRYPOINT_SCRIPT_NAME} ${image_ENTRYPOINT_SCRIPT_DIR}

# Install packages
RUN apt-get update && apt-get install --no-install-recommends -y \
	git \
	vim \
	make \
	curl \
	ca-certificates \
	xz-utils \
    && eval "${DOWNLOAD_TOOLCHAIN}" \
	&& tar -vxf $(eval "${GET_TOOLCHAIN_FILENAME}") -C ${image_TOOLCHAIN_DIR} \
	&& rm -rf \
		$(eval "${GET_TOOLCHAIN_FILENAME}") \
		${image_INSTALL_SCRIPTS_DIR} \
	&& apt-get clean

# Add User
RUN groupadd -r ${USER_NAME} \
    && useradd -rlm -d /home/${USER_NAME} -g ${USER_NAME} ${USER_NAME}
USER ${USER_NAME}
COPY ${local_DOT_FILES_DIR} /home/${USER_NAME}

#####
# Constants Updates
#####
ENV image_INSTALL_SCRIPTS_DIR=""

#####
# "Function" Updates
#####
ENV GET_TOOLCHAIN_FILENAME="ls ${image_TOOLCHAIN_DIR} | grep '^gcc-\S*-none-eabi$'"
ENV DOWNLOAD_TOOLCHAIN=""

#####
# Entrypoint Setup
#####
ENTRYPOINT ["/bin/bash", "-c", "${image_ENTRYPOINT_SCRIPT_DIR}/${ENTRYPOINT_SCRIPT_NAME} \"${@}\"", "--"]
CMD ["echo", "hello from inside the raxt"]
