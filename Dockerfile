ARG BUILD_FROM=nvcr.io/nvidia/l4t-base:r32.3.1
FROM ${BUILD_FROM}
# hadolint ignore=DL3006

COPY qemu-aarch64-static /usr/bin/

# Environment variables
ENV \
    DEBIAN_FRONTEND="noninteractive" \
    HOME="/root" \
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color"

# Copy root filesystem
COPY rootfs /

ARG BUILD_ARCH=aarch64

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install base hassio system reqs, nvidia environment reqs
RUN \
    apt-get update && \
    apt-get install -y --fix-missing --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        tzdata \
        build-essential \
        g++ \
        libhdf5-dev \
        libhdf5-serial-dev \
        hdf5-tools \
        python3-dev \
        python3-pip \
        python3-h5py \
        python3-setuptools

RUN \
    curl -o /bin/yq https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_arm64

RUN S6_ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="x86"; fi \
    && if [ "${BUILD_ARCH}" = "armv7" ]; then S6_ARCH="arm"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.4.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

#build nvidia environment
#RUN pip3 install --pre --no-cache-dir --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu
#RUN pip3 install -U numpy
RUN pip3 install -U --no-cache-dir pip

# Cleanup
WORKDIR /
RUN \
    rm -fr \
        /tmp/* \
        /var/{cache,log}/* \
        /var/lib/apt/lists/*
# Entrypoint & CMD
ENTRYPOINT [ "/init" ]

# Build arugments
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Addon NVIDIA base for ${BUILD_ARCH}" \
    io.hass.description="JPD Hass.io Add-ons: ${BUILD_ARCH} NVIDIA base image" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="base" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="John Dowling <john.patrick.dowling@gmail.com>" \
    org.label-schema.description="JPD Hass.io Add-ons: ${BUILD_ARCH} NVIDIA base image" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="Addon NVIDIA base for ${BUILD_ARCH}" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://addons.community" \
    org.label-schema.usage="https://github.com/johnpdowling/addon-nvidia-base/blob/master/README.md" \
    org.label-schema.vcs-ref=${REF} \
    org.label-schema.vcs-url="https://github.com/johnpdowling/addon-nvidia-base" \
    org.label-schema.vendor="John Dowling"
