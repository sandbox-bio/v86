#!/bin/bash

./build-container.sh && \
	./build-state.js && \
	zstd -f ../../../images/debian-state-base.bin && \
	cp ../../../images/debian-state-base.bin.zst ../../../../sandbox.bio/static/v86/
