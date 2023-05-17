# Notes

### Update image

```bash
cd tools/docker/debian
./build-container.sh && ./build-state.js && zstd ../../../images/debian-state-base.bin
# Go to http://localhost:9000/examples/debian.html
```

### Installation

* Install rust
* Run `rustup target add wasm32-unknown-unknown`
* Run `make all`
* Run `make build/xterm.js`
