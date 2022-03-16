# Use Alpine with Glibc for the toolchain
FROM ubuntu:latest

# Constants
ENV TOOLCHAIN_INSTALL_DIR="/opt/gcc-arm-none-eabi"
ENV TOOLCHAIN_SCRIPT_NAME="get_latest_gcc-arm-none-eabi.sh"
#####
# IMPORTANT NOTE: update entrypoint directive by hand
ENV ENTRYPOINT_SCRIPT_NAME="container_entrypoint.sh"
ENV ENTRYPOINT_SCRIPT_DIR="/etc"
# IMPORTANT NOTE: update entrypoint directive by hand
#####
#	why: in order to have entrypoint eval env var, must use /bin/sh -c as command.  If you do this,
#		 then the entrypoint script has no way of knowing and therefore executing the CMD passed to
#		 the container;  CMD is appended to entrypoint.
#####

# "Functions"
# can use eval to resolve layered environment variables
ENV GET_TOOLCHAIN="${TOOLCHAIN_INSTALL_DIR}/${TOOLCHAIN_SCRIPT_NAME} -o ${TOOLCHAIN_INSTALL_DIR}"
ENV GET_TOOLCHAIN_FILENAME="${GET_TOOLCHAIN} --name-only"

# Ensure installation directory exists
WORKDIR ${TOOLCHAIN_INSTALL_DIR}

COPY ${TOOLCHAIN_SCRIPT_NAME} ${TOOLCHAIN_INSTALL_DIR}
# If there is a local toolchain, copy it into container (saves time; don't have redownload)
COPY gcc-arm-none-eabi*tar.xz ${TOOLCHAIN_INSTALL_DIR}

# Ensure entrypoint directory exists
WORKDIR ${ENTRYPOINT_SCRIPT_DIR}
COPY ${ENTRYPOINT_SCRIPT_NAME} ${ENTRYPOINT_SCRIPT_DIR}

RUN apt-get update && apt-get install --no-install-recommends -y \
	git \
	vim \
	make \
	curl \
	ca-certificates \
	xz-utils \
	&& eval "${GET_TOOLCHAIN}" \
	&& tar -vxf $(eval "${GET_TOOLCHAIN_FILENAME}") -C ${TOOLCHAIN_INSTALL_DIR} \
	&& rm -rf \
		$(eval "${GET_TOOLCHAIN_FILENAME}") \
		${TOOLCHAIN_INSTALL_DIR}/${TOOLCHAIN_SCRIPT_NAME} \
	&& apt-get clean

# "Function" updates after removing build tools
ENV GET_TOOLCHAIN_FILENAME="ls ${TOOLCHAIN_INSTALL_DIR} | grep '^gcc-\S*-none-eabi$'"
ENV GET_TOOLCHAIN="toolchain fetch script removed... this function is no longer valid."

# When starting container, entrypoint is run and cmd is appended to it.
ENTRYPOINT ["/etc/container_entrypoint.sh"]
CMD [ "echo", "hello from inside the raxt" ]
