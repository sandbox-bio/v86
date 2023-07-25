FROM i386/debian:bullseye-20230522

ENV DEBIAN_FRONTEND noninteractive

# ------------------------------------------------------------------------------
# Base image
# ------------------------------------------------------------------------------
RUN apt update && \
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

# Utilities
RUN apt --yes --no-install-recommends install vim nano less curl

# ------------------------------------------------------------------------------
# Bioinformatics
# ------------------------------------------------------------------------------

# Shared dependencies
RUN apt --yes --no-install-recommends install \
    git ca-certificates gcc make g++ cmake autoconf libc6-dev autotools-dev automake libtool build-essential

# === Samtools ====
RUN apt install -y zlib1g zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libncurses5-dev
# Htslib
RUN cd /root/ && \
    git clone --recursive https://github.com/samtools/htslib.git && cd htslib && git checkout 1.17 && \
    autoreconf -i && ./configure && make && make install
# Samtools
RUN cd /root/ && \
    git clone --recursive https://github.com/samtools/samtools.git && \
    cd samtools && git checkout 1.17 
RUN cd /root/samtools && \
    autoheader && \
    autoconf -Wno-syntax && \
    ./configure && \
    make && make install

# Seqtk
RUN git clone https://github.com/lh3/seqtk.git && cd seqtk && make

# Freebayes
RUN apt install -y wget meson ninja-build pkg-config
RUN cd /root/ && git clone --recursive https://github.com/freebayes/freebayes.git
RUN cd /root/freebayes && meson build/ --buildtype debug
RUN cd /root/freebayes/build && ninja

# Kraken2
RUN cd /root && git clone https://github.com/DerrickWood/kraken2.git
RUN cd /root/kraken2/ && mkdir /root/kraken2/install && ./install_kraken2.sh /root/kraken2/install

# Lumpy
RUN cd /root && git clone --recursive https://github.com/arq5x/lumpy-sv.git
RUN cd /root/lumpy-sv && make && cp bin/* /usr/local/bin/.

# Jellyfish
RUN apt install -y jellyfish

# Bcftools
RUN cd /root && \
    git clone https://github.com/samtools/bcftools.git && \
    cd bcftools && make && make install

# Bedtools
RUN cd /root && \
    git clone https://github.com/arq5x/bedtools2.git && \
    cd bedtools2 && make && make install

# Minimap2
RUN cd /root && git clone https://github.com/lh3/minimap2 && cd minimap2 && make

# # FastQC, Picard, Trimmomatic -- Docker image won't build on Mac OS if install Java
# RUN apt-get install -y openjdk-17-jdk
# RUN apt install -y fastqc picard-tools
# RUN cd /root && curl -O "http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip" && unzip "Trimmomatic-0.39.zip"

# Mummer
RUN cd /root && curl -L -O "https://github.com/mummer4/mummer/releases/download/v4.0.0rc1/mummer-4.0.0rc1.tar.gz" && tar -xvf "mummer-4.0.0rc1.tar.gz"
RUN cd /root/mummer-4.0.0rc1 && autoreconf -fi && ./configure && make && make install
RUN rm /root/mummer-4.0.0rc1.tar.gz

# Kallisto
RUN cd /root && git clone https://github.com/pachterlab/kallisto.git && cd kallisto && git checkout v0.48.0 && mkdir build && cd build && cmake .. && make && make install 

# Bowtie2
RUN cd /root && git clone https://github.com/BenLangmead/bowtie2.git
RUN cd /root/bowtie2 && \
    sed -i "s/BITS := 32/BITS := 64/" Makefile && \
    make SSE_FLAG="-msse2" && make install

# Cleanup (Move up)

# # SPADES
# RUN cd /root && curl -L -O "https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5.tar.gz" && tar -xzf SPAdes-3.15.5.tar.gz
# RUN cd /root/SPAdes-3.15.5 && git clone https://github.com/simd-everywhere/simde.git
# RUN cd /root/SPAdes-3.15.5 && grep --include \*.hpp --include \*.h --include \*.cpp --include \*.c -R "emmintrin.h" -l . | xargs -n1 -I{} sed -i 's|#include <emmintrin.h>|#define SIMDE_ENABLE_NATIVE_ALIASES\n#include "simde\/simde\/x86\/sse2.h"|g' "{}"
# RUN cd /root/SPAdes-3.15.5 && grep --include \*.hpp --include \*.h --include \*.cpp --include \*.c -R "xmmintrin.h" -l . | xargs -n1 -I{} sed -i 's|#include <xmmintrin.h>|#include "simde\/simde\/x86\/sse.h"|g' "{}"
# RUN cd /root/SPAdes-3.15.5 && ./spades_compile.sh

# # Salmon
# RUN cd /root && git clone https://github.com/COMBINE-lab/salmon.git
# # Move up
# RUN apt-get install -y unzip
# RUN cd /root/salmon && mkdir build && cd build && cmake -DFETCH_BOOST=TRUE .. && make

# Hisat2 (64-bit)
# RUN cd /root && git clone https://github.com/DaehwanKimLab/hisat2.git
# RUN cd /root/hisat2 && make

# Python tools: MultiQC, Cutadapt, Sniffles
RUN cd /root && apt-get install -y python3-pip
RUN pip3 install multiqc cutadapt sniffles

# NGS simulator
RUN cd /root && git clone https://github.com/RAHenriksen/NGSNGS.git && cd NGSNGS && make HTSSRC=../htslib

RUN apt-get install -y man man-db

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
RUN echo "alias ll='ls -latrsh'" >> /root/.bashrc

COPY getty-noclear.conf getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY logind.conf /etc/systemd/logind.conf
COPY boot-9p /etc/initramfs-tools/scripts/boot-9p

# this needs to be commented out in order to boot from hdd
RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u

# Cleanup (doesn't seem to impact size)
RUN apt-get remove -y gcc make autoconf meson ninja-build build-essential

RUN apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm -r /usr/share/doc/* && \
    rm -r /usr/share/man/* && \
    rm -r /usr/share/locale/?? && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
