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
RUN apt --yes --no-install-recommends install vim nano less curl man-db

# Shared dependencies for bioinformatics tools
RUN apt --yes --no-install-recommends install \
    git ca-certificates gcc make g++ cmake autoconf libc6-dev autotools-dev automake libtool \
    build-essential zlib1g zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev \
    libncurses5-dev wget meson ninja-build pkg-config


# ------------------------------------------------------------------------------
# Bioinformatics tools - sandbox.bio v1
# ------------------------------------------------------------------------------

ENV INSTALL_DIR=/usr/local/bin

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

WORKDIR /root/build

# jq, tree
RUN apt install -y jq tree

# Seqtk
RUN git clone --branch ${VERSION_SEQTK} https://github.com/lh3/seqtk.git && cd seqtk && \
    make && make install

# fasttree
RUN curl -O http://www.microbesonline.org/fasttree/FastTree-${VERSION_FASTTREE}.c && \
    gcc -O3 -finline-functions -funroll-loops -Wall -o FastTree FastTree-${VERSION_FASTTREE}.c -lm && install FastTree ${INSTALL_DIR}

# kalign
RUN git clone --branch ${VERSION_KALIGN} https://github.com/TimoLassmann/kalign.git && cd kalign && \
    mkdir build && cd build && cmake .. && make && make test && make install

# fastp
RUN git clone --branch ${VERSION_FASTP} https://github.com/OpenGene/fastp.git && cd fastp && \
    make && make install

# lsd2
RUN git clone --branch ${VERSION_LSD2} https://github.com/tothuhien/lsd2.git && cd lsd2/src && \
    make && install lsd2 ${INSTALL_DIR}

# tn93
RUN git clone --branch ${VERSION_TN93} https://github.com/veg/tn93.git && cd tn93 && \
    cmake . && make install

# Bedtools
RUN git clone --branch ${VERSION_BEDTOOLS} https://github.com/arq5x/bedtools2.git && cd bedtools2 && \
    make && make install

# Minimap2
RUN git clone --branch ${VERSION_MINIMAP} https://github.com/lh3/minimap2.git && cd minimap2 && \
    make && install minimap2 ${INSTALL_DIR}

# Bowtie2
RUN git clone --branch ${VERSION_BOWTIE} https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && \
    sed -i "s/BITS := 32/BITS := 64/" Makefile && make SSE_FLAG="-msse2" && make install

# Htslib (depends on htslib)
RUN git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/htslib.git && cd htslib && \
    autoreconf -i && ./configure && make && make install

# Samtools (depends on htslib)
RUN git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/samtools.git && cd samtools && \
    autoheader && autoconf -Wno-syntax && ./configure && make && make install

# Bcftools (depends on htslib)
RUN git clone --recursive --branch ${VERSION_HTSLIB} https://github.com/samtools/bcftools.git && cd bcftools && \
    make && make install

# ivar (depends on htslib)
RUN git clone --branch ${VERSION_IVAR} https://github.com/andersen-lab/ivar.git && cd ivar && \
    ./autogen.sh && ./configure && make && make install


# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

RUN rm -rf /root/build
RUN mkdir /root/tutorial
RUN echo "alias ll='ls -latrsh';" >> /root/.bashrc

COPY getty-noclear.conf getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY logind.conf /etc/systemd/logind.conf
COPY boot-9p /etc/initramfs-tools/scripts/boot-9p

# this needs to be commented out in order to boot from hdd
RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u

# Cleanup (doesn't seem to impact size)
RUN apt-get remove -y gcc g++ make cmake automake autoconf meson ninja-build build-essential

RUN apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm -r /usr/share/locale/?? && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
