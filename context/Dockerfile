# phlax/protobuf2dev
#
# VERSION       0.0.1

ARG BUILD_FROM=golang:1.14-buster

# Root stage
FROM $BUILD_FROM

MAINTAINER Ryan Northey <ryan@synca.io>

RUN apt-get update \
	&& apt-get install -y -qq apt-transport-https git build-essential protobuf-compiler unzip \
	&& cd /tmp \
	&& wget -q https://github.com/bazelbuild/bazel/releases/download/3.5.0/bazel_3.5.0-linux-x86_64.deb \
	&& pwd \
	&& ls -lh \
	&& dpkg -i bazel_3.5.0-linux-x86_64.deb \
	&& rm bazel_3.5.0-linux-x86_64.deb \
	&& mkdir -p /source

WORKDIR /source
