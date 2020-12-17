FROM ufoym/deepo:all-jupyter-py36-cu101 AS rootBuilder
SHELL ["/bin/bash", "-c"]
ENV LANG C.UTF-8

# use kakao apt server
RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
    && apt-get update 

RUN mkdir /dockerbuild && \
    cd /dockerbuild

# Install ROOT
RUN apt install -y libxpm-dev libxft-dev qt5-default qtwebengine5-dev python3.6-dev

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
    cmake --build . --target install -- -j40

RUN pip install metakernel
RUN mkdir -p /root/.local/share/jupyter/kernels && \
    cp -r /usr/local/root/etc/notebook/kernels/root /root/.local/share/jupyter/kernels
RUN mkdir -p /jupyter_workspace

RUN rm -rf /git-repo

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 6006

ENTRYPOINT /entrypoint.sh
