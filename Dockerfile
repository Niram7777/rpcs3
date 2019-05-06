ARG U_ID
ARG G_ID

FROM nvidia_ubuntu_19.04-devel
MAINTAINER Marin "marin6314@gmail.com"

# apt need access to /tmp
RUN chmod 777 /tmp

RUN apt update && apt install -y \
	cmake build-essential \
	libasound2-dev libpulse-dev \
	libopenal-dev libglew-dev \
	zlib1g-dev libedit-dev \
	libvulkan-dev libudev-dev \
	git libevdev-dev \
	alsa-utils libgles2-mesa-dev \
	bash gdb

RUN apt install -y \
    clang \
    clang-tidy \
    clang-tools

RUN apt install -y \
    qtbase5-private-dev \
    qtdeclarative5-dev \
    qtbase5-dev \
    qt5-default \
    libqjson-dev

# not mandatory but 'vulkaninfo' usefull for debug
RUN apt install -y vulkan-tools
# strace alsa-base pulseaudio

# libnvidia-gl-418 is a big package so pick debian package for 'libnvidia-glvkspirv.so.418.56'
#RUN apt install -y libnvidia-gl-418
RUN apt install -y curl
ENV NVIDIA_DRIVER_VERSION "418.56-2"
RUN curl -O http://ftp.fr.debian.org/debian/pool/non-free/n/nvidia-graphics-drivers/libnvidia-glvkspirv_"$NVIDIA_DRIVER_VERSION"_amd64.deb && \
    dpkg -i libnvidia-glvkspirv_"$NVIDIA_DRIVER_VERSION"_amd64.deb && \
    apt install -f && \
    rm libnvidia-glvkspirv_"$NVIDIA_DRIVER_VERSION"_amd64.deb
# To get rid of 'COPY... ICD manifest file' in Dockerfile, install :
#nvidia-egl-common nvidia-vulkan-common

# To avoid passing '--device /dev/nvidia-modeset', should create device but cannot reload module
#  but is it cleaner ? 
#RUN apt install -y nvidia-modprobe
#RUN mknod -m 666 /dev/nvidia-modeset c 195 254
#RUN nvidia-modprobe -m -u -c 0 -i 0

RUN apt install -y \
    binutils-dev build-essential cmake git libcurl4-openssl-dev libdw-dev libiberty-dev python zlib1g-dev

RUN git clone https://github.com/SimonKagstrom/kcov.git && \
    mkdir -p kcov/build && \
    cd kcov/build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j8 && \
    make install

RUN rm -rf kcov

RUN apt install -y ccache && /usr/sbin/update-ccache-symlinks

# Create non root user
# Replace 1000 with your user / group id
ENV uid=${U_ID} \
	gid=${G_ID} \
	HOME=/home/developer \
    XDG_RUNTIME_DIR=$HOME/xdg 

RUN groupadd developer && \
	groupmod --gid $uid developer && \
	useradd developer \
        --uid $uid \
        --gid $uid \
        -s /bin/bash \
        --create-home && \
    umask 000

USER developer

VOLUME $HOME/rpcs3

WORKDIR $HOME/rpcs3

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

