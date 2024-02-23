FROM i386/debian:bookworm-20230904-slim
WORKDIR /root/build

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

ENV INSTALL_DIR=/usr/local/bin
ENV DEBIAN_FRONTEND noninteractive

# ------------------------------------------------------------------------------
# Base image
# ------------------------------------------------------------------------------

RUN <<BASE_IMAGE

apt update && \
    apt --yes --no-install-recommends install \
        linux-image-686 grub2 systemd libterm-readline-perl-perl locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    chsh -s /bin/bash && \
    echo "root:root" | chpasswd && \
    mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d/ && \
    systemctl enable serial-getty@ttyS0.service && \
    rm /lib/systemd/system/getty.target.wants/getty-static.service && \
    rm /etc/motd /etc/issue && \
    systemctl disable systemd-timesyncd.service && \
    systemctl disable apt-daily.timer && \
    systemctl disable apt-daily-upgrade.timer && \
    systemctl disable dhcpcd.service && \
    echo "tmpfs /tmp tmpfs nodev,nosuid 0 0" >> /etc/fstab

# Re-enable man pages (not there by default since using a slim version of the Debian Docker image)
sed -i "s|path-exclude /usr/share/man/\*||" /etc/dpkg/dpkg.cfg.d/docker

# General utilities
apt --yes --no-install-recommends install vim nano less curl git man-db \
    ca-certificates make cmake autoconf libbz2-dev liblzma-dev libncurses5-dev \
    zlib1g-dev libcurl4-gnutls-dev libssl-dev gcc g++ libc6-dev autotools-dev \
    automake libtool build-essential zlib1g

BASE_IMAGE

# Install Rust. It's needed by tools like MMSeqs2 and Foldseek, but "apt-get install -y rustc" installs a version that is too old.
COPY --from=i386/rust:1.72-slim-bookworm /usr/local/rustup /usr/local/rustup
COPY --from=i386/rust:1.72-slim-bookworm /usr/local/cargo /usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH


# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v1
# ------------------------------------------------------------------------------

RUN apt-get install -y jq tree seqtk fasttree kalign bedtools

# Htslib: disabled features that depend on the network; modified CFLAGS to remove "-g"
RUN git clone --recursive --branch 1.18 https://github.com/samtools/htslib.git && cd htslib && \
    autoreconf -i && ./configure --disable-plugins --disable-libcurl --disable-gcs --disable-s3 && \
    make CFLAGS="-O2 -fvisibility=hidden" && make install

# samtools: apt-get version is 1.16.1; modified CFLAGS to remove "-g"
RUN git clone --recursive --branch 1.18 https://github.com/samtools/samtools.git && cd samtools && \
    autoheader && autoconf -Wno-syntax && ./configure && make CFLAGS="-O2" && make install

# bcftools (the apt-get version is 1.16; modified CFLAGS to remove "-g"
RUN git clone --recursive --branch 1.18 https://github.com/samtools/bcftools.git && cd bcftools && \
    autoheader && autoconf && ./configure --disable-bcftools-plugins --disable-libgsl --disable-perl-filters && \
    make CFLAGS="-O2" && make install

# fastp (using older version since latest needs libisal, which gives 32-bit errors)
RUN git clone --branch v0.20.1 https://github.com/OpenGene/fastp.git && cd fastp && \
    make LD_FLAGS="-lz -lpthread -static" && make install

# Bowtie2
RUN git clone --branch v2.5.1 https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && \
    sed -i "s/BITS := 32/BITS := 64/" Makefile && make SSE_FLAG="-msse2" && make install

# Minimap2 (manual install because "apt-get install -y minimap2" gives opcode errors)
RUN apt update
RUN git clone --recursive --branch v2.26 https://github.com/lh3/minimap2.git && cd minimap2 && \
    make && install minimap2 ${INSTALL_DIR}


# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v2
# ------------------------------------------------------------------------------

RUN apt-get install -y jellyfish seqkit kraken2 mummer

# CSVtk
RUN curl -L -O "https://github.com/shenwei356/csvtk/releases/download/v0.27.2/csvtk_linux_386.tar.gz" && \
    tar xvzf "csvtk_linux_386.tar.gz" && install csvtk ${INSTALL_DIR}

# Kallisto (using 0.48.0 because get build error with 0.50.0)
# This version uses an older htslib that breaks with autoconf >2.69, so cherry pick just that fix
RUN git clone --branch v0.48.0 https://github.com/pachterlab/kallisto.git && cd kallisto && \
    git cherry-pick -n 94e00d9a924345a26f03ccbb561b1d3bd4165712 -X theirs && \
    mkdir build && cd build && cmake -DLINK=static .. && make && make install && cd ../../

# MMSeqs2 (CMake flags: https://github.com/soedinglab/MMseqs2/wiki#customizing-compilation-through-cmake)
RUN git clone --recursive --branch 14-7e284 https://github.com/soedinglab/MMseqs2.git && cd MMseqs2 && \
    mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RELEASE -DHAVE_TESTS=0 -DREQUIRE_OPENMP=0 -DNATIVE_ARCH=0 -DHAVE_SSE2=1 .. && \
    make && make install 

# Foldseek
RUN git clone --recursive --branch 8-ef4e960 https://github.com/steineggerlab/foldseek && cd foldseek && \
    mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RELEASE -DHAVE_TESTS=0 -DREQUIRE_OPENMP=0 -DNATIVE_ARCH=0 -DHAVE_SSE2=1 .. && \
    make && make install 

# ViralConsensus
RUN git clone --branch 0.0.4 https://github.com/niemasd/ViralConsensus.git && cd ViralConsensus && \
    make && install viral_consensus ${INSTALL_DIR}

# HyPhy
RUN git clone --branch 2.5.59 https://github.com/veg/hyphy.git && cd hyphy && \
    cmake . && make install

# FreeBayes: compile from source and compile into static (otherwise, get 20 .bin files)
RUN apt-get install -y meson ninja-build pkg-config
RUN git clone --branch v1.3.7 --recursive https://github.com/freebayes/freebayes.git && cd freebayes && \
    meson build -Dstatic=true -Dprefer_system_deps=false --buildtype release && cd build && ninja && \
    install freebayes ${INSTALL_DIR}/freebayes


# ------------------------------------------------------------------------------
# Utilities
# ------------------------------------------------------------------------------

RUN apt-get remove -y vim && \
    apt-get install -y vim-tiny && \
    install /usr/bin/vim.tiny ${INSTALL_DIR}/vim


# ------------------------------------------------------------------------------
# Custom sandbox.bio commands
# ------------------------------------------------------------------------------

COPY sandbox_bio_open.sh /root/build/open
COPY sandbox_bio_download.sh /root/build/download
COPY sandbox_bio_curl.sh /root/build/curl
RUN apt-get remove -y curl && \
    install /root/build/open ${INSTALL_DIR}/open && \
    install /root/build/download ${INSTALL_DIR}/download && \
    install /root/build/curl ${INSTALL_DIR}/curl


# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

# Fix manpage issue
RUN apt-get install -y --reinstall coreutils grep

# Setup
WORKDIR /root/
RUN rm -rf /root/build && \
    mkdir /root/tutorial && \
    echo "alias ll='ls -latrsh';" >> /root/.bashrc

COPY getty-noclear.conf getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY logind.conf /etc/systemd/logind.conf
COPY boot-9p /etc/initramfs-tools/scripts/boot-9p

RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u && \
    rustup self uninstall -y && \
    apt-get remove --purge -y gcc gcc-12 g++ make cmake automake autoconf build-essential libbz2-dev liblzma-dev libncurses5-dev zlib1g-dev libcurl4-gnutls-dev libssl-dev libc6-dev autotools-dev libtool python3-pip pandoc meson ninja-build pkg-config && \
    apt-get autoremove --purge -y && \
    apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
