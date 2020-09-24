# phlax/protobuf2dev
#
# VERSION       0.0.1

ARG BUILD_FROM=golang:alpine

# Root stage
FROM $BUILD_FROM

MAINTAINER Ryan Northey <ryan@synca.io>

ENV GO111MODULE=on
RUN go get github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema \
	&& go install github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema
