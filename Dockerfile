# Docker base image for deb builds
FROM ubuntu:trusty
MAINTAINER Art
RUN apt-get update && apt-get install -y build-essential \
    autoconf \
    automake \
    autotools-dev \
    debhelper \
    dh-make \
    debmake \
    devscripts \
    fakeroot \
    file \
    git \
    gnupg \
    lintian \
    patch \
    patchutils \
    pbuilder \
    perl \
    python \
    quilt
