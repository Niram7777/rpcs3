#FROM nvidia/opengl:1.0-glvnd-devel-ubuntu18.04
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

# Create non root user
# Replace 1000 with your user / group id
ENV uid=1000 \
	gid=1000 \
	HOME=/home/developer \
    XDG_RUNTIME_DIR=$HOME/xdg 

RUN groupadd developer && \
	groupmod --gid $uid developer && \
	useradd developer \
        --uid $uid \
        --gid $uid \
        -s /bin/bash \
        --create-home
#        --groups audio,messagebus

USER developer

VOLUME $HOME/rpcs3

WORKDIR $HOME/rpcs3

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

#(gdb) --cap-add=SYS_PTRACE --security-opt seccomp=unconfined
#docker run --runtime=nvidia \
#	--device /dev/nvidia-modeset --device /dev/snd --device /dev/input \
#	 -ti --rm -e DISPLAY \
#	-v /tmp/.X11-unix:/tmp/.X11-unix -v /usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/nvidia_icd.json
#	-v /media/marin/Samsung/Git/rpcs3/build:/home/developer/rpcs3/build -v /media/marin/Samsung/Emu/PS3:/home/developer/PS3 -v /media/marin/Maxtor/rpcs3:/home/developer/.config/rpcs3 \
#	rpcs3

