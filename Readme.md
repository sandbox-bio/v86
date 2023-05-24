# Notes

### Update image

```bash
cd tools/docker/debian
./build-container.sh && ./build-state.js && zstd ../../../images/debian-state-base.bin
# Go to http://localhost:9000/examples/debian.html
```

### Installation

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown
make all
make build/xterm.js
```
