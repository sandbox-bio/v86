#!/bin/bash

./build-container.sh && \
	./build-state.js && \
	zstd -f ../../../images/debian-state-base.bin && \
	cp ../../../images/debian-state-base.bin.zst ../../../../sandbox.bio/static/v86/ && \
	cp -n -r ../../../images/debian-9p-rootfs-flat/ ../../../../sandbox.bio/static/v86/debian-9p-rootfs-flat/
