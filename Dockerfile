# Docker base image for deb builds
FROM ubuntu:trusty
MAINTAINER Art
# Install aptly for testing repo management locally
RUN echo "deb http://repo.aptly.info/ squeeze main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keys.gnupg.net --recv-keys E083A3782A194991 && \
    apt-get update && \
    apt-get install -y aptly 
# Install typical pre-requisites for debian package builds
RUN apt-get update && apt-get install -y \ 
    build-essential \
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
    quilt \
    curl \
    wget \
    tree \
    python-virtualenv

ADD src /root/src
# GPG secret key pass-phrase = pizza
RUN gpg --import /root/src/public.pizza.gpg
RUN gpg --import /root/src/secret.pizza.gpg
RUN apt-key add /root/src/public.pizza.gpg
