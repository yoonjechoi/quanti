FROM nvidia/cuda:11.4.2-cudnn8-devel-ubuntu20.04 AS rootBuilder
# use kakao apt server
RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
    && apt-get update 

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

RUN apt-get install -y python3 python3-pip git cmake
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN mkdir /dockerbuild && \
    cd /dockerbuild


# Install ROOT
RUN apt-get install -y libxpm-dev libxft-dev qt5-default qtwebengine5-dev libssl-dev

RUN mkdir -p /git-repo && cd /git-repo && \
    git clone --branch v6-22-00-patches https://github.com/root-project/root.git root_src && \
    cd /git-repo/root_src

RUN mkdir -p /git-repo/root_build /usr/local/root

RUN cd /git-repo/root_build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/root \
    -Dbuiltin_openssl=On \
    -Dcuda=On \
    -Dcudnn=On \
    -Dqt5web=On \
    /git-repo/root_src && \
    cmake --build . --verbose --target install -- -j40


FROM nvidia/cuda:11.4.2-cudnn8-runtime-ubuntu20.04 AS runtime

SHELL ["/bin/bash", "-c"]
ENV LANG C.UTF-8

# use kakao apt server
RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
    && apt-get update 
 
# install python3.8
RUN apt-get install -y python3 python3-pip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# install jupyter
RUN pip install --no-input jupyterlab

# install pytorch
RUN pip install --no-input \
    torch==1.9.1+cu111 torchvision==0.10.1+cu111 torchaudio==0.9.1 -f https://download.pytorch.org/whl/torch_stable.html

# install tensorflow
RUN pip install --no-input tensorflow

# copy root from rootBuilder
COPY --from=rootBuilder /usr/local/root /usr/local/root

# install root required packages
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
RUN apt-get install -y dpkg-dev cmake g++ gcc binutils libx11-dev libxpm-dev libxft-dev libxext-dev python libssl-dev

# setup root kernel in jupyter
RUN pip install --no-input metakernel
RUN mkdir -p /root/.local/share/jupyter/kernels && \
    cp -r /usr/local/root/etc/notebook/kernels/root /root/.local/share/jupyter/kernels


RUN echo "source /usr/local/root/bin/thisroot.sh" > /etc/profile.d/root.sh

RUN mkdir -p /workspace
RUN chmod -R 777 /workspace
    
#ENTRYPOINT ["jupyter-lab", "--no-browser", "--allow-root", "--ip=0.0.0.0", "--notebook-dir=/workspace"]

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


