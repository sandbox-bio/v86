# Notes

### Installation on MacOS

```bash
# Install Rust, wget, zstd
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown
brew install wget ztd # used by Makefile

# Go to https://www.java.com/en/download/ to download the Java 8 runtime

# Build
make all
make build/xterm.js
```

### Set up server

```bash
python3 -m http.server 9000
```

### Update image

```bash
cd tools/docker/debian
./generate.sh

# Go to http://localhost:9000/examples/debian.html
```
