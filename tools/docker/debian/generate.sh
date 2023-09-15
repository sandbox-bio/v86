#!/bin/bash

rm -rf ../../../images/
./build-container.sh && \
	./build-state.js && \
	zstd -f ../../../images/debian-state-base.bin && \
	cp ../../../images/debian-state-base.bin.zst ../../../../sandbox.bio/static/v86/ && \
	rm -rf ../../../../sandbox.bio/static/v86/debian-9p-rootfs-flat/ && \
	cp -n -r ../../../images/debian-9p-rootfs-flat/ ../../../../sandbox.bio/static/v86/debian-9p-rootfs-flat/
