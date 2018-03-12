FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
MAINTAINER Leo <zhangshichaochina@gmail.com>

RUN apt-get update && apt-get install -y \
        build-essential cmake git wget && \
    apt-get install -y --no-install-recommends \
	pkg-config unzip ffmpeg qtbase5-dev python3-dev python3 python3-numpy python3-py python-dev python-numpy python-py \
	libgtk2.0-dev libjpeg-dev libpng12-dev libtiff5-dev libjasper-dev zlib1g-dev libglew-dev libprotobuf-dev \ 
	libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libxine2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev \	
        libv4l-dev libtbb-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev \
        libvorbis-dev libxvidcore-dev v4l-utils libhdf5-serial-dev libeigen3-dev libtbb-dev libpostproc-dev && \
    rm -rf /var/lib/apt/lists/*

# Build OpenCV with CUDA
RUN \
    cd ~ && \ 
    git clone https://github.com/Itseez/opencv.git && \
    git clone https://github.com/Itseez/opencv_contrib.git && \ 

    cd ~/opencv && \ 
    mkdir build && \ 
    cd build && \
    cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr/local \
	-DBUILD_EXAMPLES=OFF \
	-DBUILD_opencv_java=OFF \
	-DBUILD_opencv_python2=ON \
	-DBUILD_opencv_python3=ON \
	-DWITH_FFMPEG=ON \
	-DWITH_CUDA=ON \
	-DWITH_GTK=ON \
	-DWITH_TBB=ON \
	-DWITH_V4L=ON \
	-DWITH_QT=ON \
	-DWITH_OPENGL=ON \
	-DWITH_CUBLAS=ON \	
	-DWITH_1394=OFF \
	-DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-9.0 \
	-DCUDA_ARCH_PTX="" \
	-DCUDA_NVCC_FLAGS="-D_FORCE_INLINES" \ 
	-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
	-DINSTALL_C_EXAMPLES=OFF \
	-DINSTALL_TESTS=OFF \
	-DOPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules .. && \

    make -j $(nproc) && \ 
    make install && \ 
    ldconfig && \
    cp ~/opencv/build/lib/cv2.so /usr/local/lib/python2.7/dist-packages/ && \
    cp ~/opencv/build/lib/cv2.so /usr/local/lib/python3.5/dist-packages/ && \
    rm -rf ~/opencv/build
ENV DEBIAN_FRONTEND noninteractive
ENV USER ubuntu
ENV HOME /home/$USER

# Create new user for vnc login.
RUN adduser $USER --disabled-password

# Install Ubuntu Unity.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ubuntu-desktop \
        gnome-panel \
        unity-lens-applications \    
        metacity \
        nautilus \
        gedit \
        xterm \
        guake \
        gnome-system-monitor \
        gnome-screensaver \
        sudo \
        vim \
        systemsettings \
        supervisor firefox \
        fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming \
        net-tools \
        curl \
        git \
        pwgen \
        libtasn1-3-bin bash-completion \
        language-pack-zh-hant language-pack-gnome-zh-hant firefox-locale-zh-hant libreoffice-l10n-zh-tw \
        libglu1-mesa \
        gconf2 \
        gconf-service \
        git \
        gvfs-bin \
        libasound2 \
        libcap2 \
        libgconf-2-4 \
        libgtk2.0-0 \
        libnotify4 \
        libnss3 \
        libxkbfile1 \
        libxss1 \
        libxtst6 \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        python \
        xdg-utils

RUN curl -L https://atom.io/download/deb > /tmp/atom.deb && \
       dpkg -i /tmp/atom.deb && \
       rm -f /tmp/atom.deb
RUN apt-get install -y --no-install-recommends \
    python3-pip python3-setuptools tilda openssh-server openssh-client && \
    pip3 install --no-cache-dir --upgrade  pip && \
    pip3 install --upgrade --no-cache-dir https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.6.0-cp35-cp35m-linux_x86_64.whl

# Copy tigerVNC binaries
ADD tigervnc-1.8.0.x86_64 /
# Clone noVNC.
RUN git clone https://github.com/novnc/noVNC.git $HOME/noVNC

# Clone websockify for noVNC
Run git clone https://github.com/kanaka/websockify $HOME/noVNC/utils/websockify

# Download ngrok.
ADD https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip $HOME/ngrok/ngrok.zip
RUN unzip -o $HOME/ngrok/ngrok.zip -d $HOME/ngrok && rm $HOME/ngrok/ngrok.zip

# Copy supervisor config
COPY supervisor.conf /etc/supervisor/conf.d/

# Set xsession of Unity
COPY xsession $HOME/.xsession

# Copy startup script
COPY startup.sh $HOME

EXPOSE 6080 5901 4040 
CMD ["/bin/bash", "/home/ubuntu/startup.sh"]
