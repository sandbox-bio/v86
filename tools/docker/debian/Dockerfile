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

# General utilities
apt --yes --no-install-recommends install vim nano less curl git man-db \
    ca-certificates make cmake autoconf libbz2-dev liblzma-dev libncurses5-dev \
    zlib1g-dev libcurl4-gnutls-dev libssl-dev gcc g++ libc6-dev autotools-dev \
    automake libtool build-essential zlib1g

BASE_IMAGE

# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v1
# ------------------------------------------------------------------------------

ENV VERSION_HTSLIB=1.18
ENV VERSION_FASTP=v0.20.1
ENV VERSION_LSD2=v.2.4.1
ENV VERSION_TN93=v.1.0.11
ENV VERSION_BOWTIE=v2.5.1

RUN <<SANDBOXBIO_V1

# Install available tools through package registry
apt-get install -y jq tree seqtk fasttree kalign bedtools minimap2 samtools bcftools ivar

# Htslib
git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/htslib.git && cd htslib && \
    autoreconf -i && ./configure && make && make install && cd -

# fastp
git clone --branch ${VERSION_FASTP} https://github.com/OpenGene/fastp.git && cd fastp && \
    make && make install && cd -

# lsd2
git clone --branch ${VERSION_LSD2} https://github.com/tothuhien/lsd2.git && cd lsd2/src && \
    make && install lsd2 ${INSTALL_DIR} && cd -

# tn93
git clone --branch ${VERSION_TN93} https://github.com/veg/tn93.git && cd tn93 && \
    cmake . && make install && cd -

# Bowtie2
git clone --branch ${VERSION_BOWTIE} https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && \
    sed -i "s/BITS := 32/BITS := 64/" Makefile && make SSE_FLAG="-msse2" && make install && cd -

SANDBOXBIO_V1


# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v2
# ------------------------------------------------------------------------------

ENV VERSION_KALLISTO=v0.48.0
ENV VERSION_VIRAL_MSA=1.1.32
ENV VERSION_CSVTK=v0.27.2

RUN <<SANDBOXBIO_V2

# Install available tools through package registry
apt-get install -y jellyfish seqkit freebayes kraken2 lumpy-sv mummer sniffles bioawk

# ViralMSA
apt-get install -y python3-biopython
curl -L -O https://raw.githubusercontent.com/niemasd/ViralMSA/${VERSION_VIRAL_MSA}/ViralMSA.py && chmod a+x ViralMSA.py && install ViralMSA.py ${INSTALL_DIR}/ViralMSA.py

# CSVtk
curl -L -O https://github.com/shenwei356/csvtk/releases/download/${VERSION_CSVTK}/csvtk_linux_386.tar.gz && tar xvzf "csvtk_linux_386.tar.gz" && install csvtk ${INSTALL_DIR}/csvtk

# Kallisto (using 0.48.0 because get build error with 0.50.0)
# This version uses an older htslib that breaks with autoconf >2.69, so cherry pick just that fix
git clone --branch ${VERSION_KALLISTO} https://github.com/pachterlab/kallisto.git && cd kallisto && \
    git cherry-pick -n 94e00d9a924345a26f03ccbb561b1d3bd4165712 -X theirs && \
    mkdir build && cd build && cmake -DLINK=static .. && make && make install && cd ../../

SANDBOXBIO_V2



# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

WORKDIR /root/
RUN rm -rf /root/build && \
    mkdir /root/tutorial && \
    echo "alias ll='ls -latrsh';" >> /root/.bashrc

COPY getty-noclear.conf getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY logind.conf /etc/systemd/logind.conf
COPY boot-9p /etc/initramfs-tools/scripts/boot-9p

# This needs to be commented out in order to boot from hdd
RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u && \
    apt-get remove -y gcc g++ make cmake automake autoconf meson ninja-build build-essential python3-pip libbz2-dev liblzma-dev libncurses5-dev zlib1g-dev libcurl4-gnutls-dev libssl-dev libc6-dev autotools-dev libtool && \
    apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
