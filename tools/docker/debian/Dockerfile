FROM i386/debian:bullseye-20230522
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
apt --yes --no-install-recommends install vim nano less curl man-db

# Shared dependencies for bioinformatics tools
apt --yes --no-install-recommends install \
    git ca-certificates gcc make g++ cmake autoconf libc6-dev autotools-dev automake libtool \
    build-essential zlib1g zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev \
    libncurses5-dev wget meson ninja-build pkg-config

BASE_IMAGE

# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v1
# ------------------------------------------------------------------------------

# Tools from v1
ENV VERSION_HTSLIB=1.18
ENV VERSION_SEQTK=v1.4
ENV VERSION_BEDTOOLS=v2.31.0
ENV VERSION_MINIMAP=v2.26
ENV VERSION_BOWTIE=v2.5.1
ENV VERSION_KALIGN=v3.3.5
ENV VERSION_IVAR=v1.4.2
ENV VERSION_FASTTREE=2.1.11
ENV VERSION_FASTP=v0.20.1
ENV VERSION_LSD2=v.2.4.1
ENV VERSION_TN93=v.1.0.11

RUN <<SANDBOXBIO_V1

# jq, tree
apt install -y jq tree

# Seqtk
git clone --branch ${VERSION_SEQTK} https://github.com/lh3/seqtk.git && cd seqtk && make && make install && cd -

# fasttree
curl -O http://www.microbesonline.org/fasttree/FastTree-${VERSION_FASTTREE}.c && \
    gcc -O3 -finline-functions -funroll-loops -Wall -o FastTree FastTree-${VERSION_FASTTREE}.c -lm && install FastTree ${INSTALL_DIR} && cd -

# kalign
git clone --branch ${VERSION_KALIGN} https://github.com/TimoLassmann/kalign.git && cd kalign && \
    mkdir build && cd build && cmake .. && make && make test && make install && cd -

# fastp
git clone --branch ${VERSION_FASTP} https://github.com/OpenGene/fastp.git && cd fastp && \
    make && make install && cd -

# lsd2
git clone --branch ${VERSION_LSD2} https://github.com/tothuhien/lsd2.git && cd lsd2/src && \
    make && install lsd2 ${INSTALL_DIR} && cd -

# tn93
git clone --branch ${VERSION_TN93} https://github.com/veg/tn93.git && cd tn93 && \
    cmake . && make install && cd -

# Bedtools
git clone --branch ${VERSION_BEDTOOLS} https://github.com/arq5x/bedtools2.git && cd bedtools2 && \
    make && make install && cd -

# Minimap2
git clone --branch ${VERSION_MINIMAP} https://github.com/lh3/minimap2.git && cd minimap2 && \
    make && install minimap2 ${INSTALL_DIR} && cd -

# Bowtie2
git clone --branch ${VERSION_BOWTIE} https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && \
    sed -i "s/BITS := 32/BITS := 64/" Makefile && make SSE_FLAG="-msse2" && make install && cd -

# Htslib
git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/htslib.git && cd htslib && \
    autoreconf -i && ./configure && make && make install && cd -

# Samtools (depends on htslib)
git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/samtools.git && cd samtools && \
    autoheader && autoconf -Wno-syntax && ./configure && make && make install && cd -

# Bcftools (depends on htslib)
git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/bcftools.git && cd bcftools && \
    make && make install && cd -

# ivar (depends on htslib)
git clone --branch ${VERSION_IVAR} https://github.com/andersen-lab/ivar.git && cd ivar && \
    ./autogen.sh && ./configure && make && make install && cd -

SANDBOXBIO_V1


# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v2
# ------------------------------------------------------------------------------

# Tools introduced in v2
ENV VERSION_SEQKIT=v2.5.1
ENV VERSION_FREEBAYES=v1.3.7
ENV VERSION_KRAKEN=v2.1.3
ENV VERSION_LUMPY=v0.3.1
ENV VERSION_MUMMER=4.0.0rc1
ENV VERSION_KALLISTO=v0.48.0
ENV VERSION_VIRAL_MSA=1.1.32

RUN <<SANDBOXBIO_V2

# Jellyfish
apt install -y jellyfish

# SeqKit
curl -L -O "https://github.com/shenwei356/seqkit/releases/download/${VERSION_SEQKIT}/seqkit_linux_386.tar.gz" && \
    tar -zvxf "seqkit_linux_386.tar.gz" && install seqkit ${INSTALL_DIR}/seqkit

# Freebayes
git clone --recursive --branch ${VERSION_FREEBAYES} https://github.com/freebayes/freebayes.git && cd freebayes && \
    meson build/ --buildtype debug && cd build && ninja && install freebayes ${INSTALL_DIR}/freebayes && cd ../..

# Kraken2
git clone --branch ${VERSION_KRAKEN} https://github.com/DerrickWood/kraken2.git && cd kraken2 && \
    ./install_kraken2.sh ${INSTALL_DIR}/ && cd -

# Lumpy
git clone --recursive --branch ${VERSION_LUMPY} https://github.com/arq5x/lumpy-sv.git && cd lumpy-sv && \
    make && cp bin/* ${INSTALL_DIR}/. && cd -

# Mummer
curl -L -O https://github.com/mummer4/mummer/releases/download/v${VERSION_MUMMER}/mummer-${VERSION_MUMMER}.tar.gz && \
    tar -xvf mummer-${VERSION_MUMMER}.tar.gz && cd mummer-${VERSION_MUMMER} && \
    autoreconf -fi && ./configure && make && make install && cd -

# Kallisto
git clone --branch ${VERSION_KALLISTO} https://github.com/pachterlab/kallisto.git && cd kallisto && \
    mkdir build && cd build && cmake .. && make && make install && cd ../../

SANDBOXBIO_V2


# In progress
RUN apt-get install -y python3-pip
RUN pip3 install biopython
RUN pip3 install sniffles
RUN curl -L -O "https://raw.githubusercontent.com/niemasd/ViralMSA/1.1.32/ViralMSA.py" && chmod a+x ViralMSA.py && install ViralMSA.py ${INSTALL_DIR}/ViralMSA.py


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
    apt-get remove -y gcc g++ make cmake automake autoconf meson ninja-build build-essential python3-pip && \
    apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm -r /usr/share/locale/?? && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
