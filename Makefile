#!/usr/bin/make -f

SHELL := /bin/bash


image:
	docker build -t phlax/protobuf2dev context

hub-image:
	docker push phlax/protobuf2dev
