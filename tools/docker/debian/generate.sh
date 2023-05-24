#!/bin/bash

./build-container.sh && \
	./build-state.js && \
	zstd ../../../images/debian-state-base.bin

