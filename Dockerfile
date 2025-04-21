FROM	debian:11
MAINTAINER	Entware team

ARG	DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update && \
    apt-get install -y \
	build-essential \
	ccache \
	curl \
	gawk \
	genisoimage \
	git-core \
	gosu \
	libdw-dev \
	libelf-dev \
	libncurses5-dev \
 	libssl-dev \
	locales \
	mc \
	pv \
	pwgen \
	python \
	python3 \
	python3-pip \
	qemu-utils \
	rsync \
	signify-openbsd \
	subversion \
	sudo \
	swig \
	unzip \
	wget \
	zstd && \
    apt-get clean && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN pip3 install -U pip
RUN pip3 install \
	pyelftools \
	pyOpenSSL \
	service_identity

ENV LANG=en_US.utf8

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN useradd -c "OpenWrt Builder" -m -d /home/me -G sudo -s /bin/bash me

USER me
WORKDIR /home/me
ENV HOME /home/me

#ENTRYPOINT /bin/bash

# ---------------- Entware toolchain build in distinct steps ----------------

# 1. Clone Entware repository (shallow)
RUN git clone --depth=1 https://github.com/Entware/Entware.git

# 2. Switch context into the repo for subsequent commands
WORKDIR /home/me/Entware

# 3. Copy device‑specific config and generate package symlinks
RUN cp configs/mipsel-3.4.config .config && \
    make package/symlinks

# 4. Fix PKG_HASH for go linux-arm64
RUN sed -i 's/^PKG_HASH:=.*/PKG_HASH:=2096507509a98782850d1f0669786c09727053e9fe3c92b03c0d96f48700282b/' tools/go-bootstrap/Makefile

# 5. Build the toolchain (parallel)
RUN make toolchain/install -j$(nproc)
