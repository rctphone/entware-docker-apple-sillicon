FROM	debian:11
MAINTAINER	Entware team

ARG	DEBIAN_FRONTEND=noninteractive
ARG	ENTWARE_CONFIG=aarch64-3.10.config

RUN \
    apt-get update && \
    apt-get install -y \
	build-essential \
	ccache \
	clang \
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
	python3-venv \
	python3-pip \
	python3-pyelftools \
	python3-cryptography \
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
RUN cp configs/${ENTWARE_CONFIG} .config && \
    make package/symlinks

# 4. Fix PKG_HASH for tools/go-bootstrap - auto-detect arch and get SHA256 from .sha256 file
RUN set -e; \
  cd /home/me/Entware; \
  GO_VER="$(sed -n 's/^PKG_VERSION:=[ \t]*//p' tools/go-bootstrap/Makefile)"; \
  GO_VERSION_FULL="go${GO_VER}"; \
  case "$(uname -m)" in \
    aarch64) GO_ARCH="arm64" ;; \
    x86_64)  GO_ARCH="amd64" ;; \
    i?86)    GO_ARCH="386"   ;; \
    *) echo "Unsupported arch: $(uname -m)"; exit 1 ;; \
  esac; \
  echo "Resolving SHA256 for ${GO_VERSION_FULL} linux/${GO_ARCH}..."; \
  GO_FILENAME="${GO_VERSION_FULL}.linux-${GO_ARCH}.tar.gz"; \
  SHA256_URL="https://dl.google.com/go/${GO_FILENAME}.sha256"; \
  echo "Fetching SHA256 from: ${SHA256_URL}"; \
  SHA256="$(curl -sL "${SHA256_URL}" | awk '{print $1}')"; \
  test -n "$SHA256" || { echo "SHA256 not found at ${SHA256_URL}"; exit 1; }; \
  sed -i "s/^PKG_HASH:=.*/PKG_HASH:=${SHA256}/" tools/go-bootstrap/Makefile; \
  echo "Set PKG_HASH=${SHA256} for ${GO_FILENAME}"

# 5. Build the toolchain
RUN make toolchain/install -j$(nproc) 
