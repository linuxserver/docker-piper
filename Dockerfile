# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PIPER_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

ENV DEBIAN_FRONTEND="noninteractive" \
  TMPDIR="/run/piper-temp"

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    patch \
    python3-venv && \
  if [ -z ${PIPER_VERSION+x} ]; then \
    PIPER_VERSION=$(curl -sL  https://pypi.python.org/pypi/wyoming-piper/json |jq -r '. | .info.version'); \
  fi && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/ubuntu/ \
    nvidia-cublas-cu12 \
    "nvidia-cudnn-cu12>=9.0,<10.0" \
    onnxruntime-gpu \
    "wyoming-piper==${PIPER_VERSION}" && \
  if [ -z ${PIPER_BIN_VERSION+x} ]; then \
    PIPER_BIN_VERSION=$(curl -sL "https://api.github.com/repos/rhasspy/piper/commits/master" \
    | jq -r .sha); \
  fi && \
  mkdir -p /tmp/piper-build /usr/share/piper && \
  curl -sL -o  \
    /tmp/piper.tar.gz -L \
    "https://github.com/rhasspy/piper/archive/${PIPER_BIN_VERSION}.tar.gz" && \
  tar xzf \
    /tmp/piper.tar.gz -C \
    /tmp/piper-build --strip-components=1 && \
  cd /tmp/piper-build && \
  cmake -Bbuild -DCMAKE_INSTALL_PREFIX=install && \
  cmake --build build --config Release && \
  cmake --install build && \
  cp -dR /tmp/piper-build/install/* /usr/share/piper && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get purge -y \
    build-essential \
    cmake \
    git \
    pkg-config && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  rm -rf \
    /var/lib/apt/lists/* \
    /tmp/*

COPY root /

VOLUME /config

EXPOSE 10200
