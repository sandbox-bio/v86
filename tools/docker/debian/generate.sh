#!/bin/bash

./build-container.sh && \
	./build-state.js && \
	zstd -f ../../../images/debian-state-base.bin
