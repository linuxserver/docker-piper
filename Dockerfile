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
    python3-venv && \
  if [ -z ${PIPER_VERSION+x} ]; then \
    PIPER_VERSION=$(curl -sL  https://pypi.python.org/pypi/wyoming-piper/json |jq -r '. | .info.version'); \
  fi && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/ubuntu/ \
    piper-tts \
    "wyoming-piper==${PIPER_VERSION}" && \
  if [ -z ${PIPER_BIN_VERSION+x} ]; then \
    PIPER_BIN_VERSION=$(curl -sL "https://api.github.com/repos/OHF-Voice/piper1-gpl/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /var/lib/apt/lists/* \
    /tmp/*

COPY root /

VOLUME /config

EXPOSE 10200
