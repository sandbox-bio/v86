FROM i386/debian:bullseye

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
RUN apt --yes --no-install-recommends install vim less

# ------------------------------------------------------------------------------
# Bioinformatics
# ------------------------------------------------------------------------------
# Install gcc/make/libc6-dev, install bioinfo tools, then remove it from image
RUN apt --yes --no-install-recommends install \
    git ca-certificates \
    gcc make g++ cmake autoconf libc6-dev autotools-dev automake  libtool

# === Samtools ====
RUN apt install -y zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev 
# Htslib
RUN cd /root/ && \
    git clone --recursive https://github.com/samtools/htslib.git && cd htslib && git checkout 1.17 && \
    autoreconf -i && ./configure && make && make install
# Samtools
RUN cd /root/ && \
    git clone --recursive https://github.com/samtools/samtools.git && \
    cd samtools && git checkout 1.17 
RUN apt install -y libncurses5-dev
RUN cd /root/samtools && \
    autoheader && \
    autoconf -Wno-syntax && \
    ./configure && \
    make && make install

# seqtk
RUN git clone https://github.com/lh3/seqtk.git && cd seqtk && make

# Freebayes
RUN apt install -y wget meson ninja-build
RUN apt install -y pkg-config zlib1g zlib1g-dev
RUN cd /root/ && git clone --recursive https://github.com/freebayes/freebayes.git
RUN cd /root/freebayes && meson build/ --buildtype debug
RUN cd /root/freebayes/build && ninja
# ninja test

# # Vsearch
# RUN cd /root/ && wget https://github.com/torognes/vsearch/archive/v2.22.1.tar.gz && tar xzf v2.22.1.tar.gz && cd vsearch-2.22.1
# RUN cd /root/vsearch-2.22.1 && ./autogen.sh
# RUN cd /root/vsearch-2.22.1 && ./configure CFLAGS="-O3" CXXFLAGS="-O3"
# RUN cd /root/vsearch-2.22.1 && make
# RUN cd /root/vsearch-2.22.1 && make install  # as root or sudo make install

# Kraken2
RUN cd /root && git clone https://github.com/DerrickWood/kraken2.git
RUN cd /root/kraken2/ && mkdir /root/kraken2/install && ./install_kraken2.sh /root/kraken2/install

# # Shasta
# RUN cd root && git clone https://github.com/paoloshasta/shasta.git
# RUN cd /root/shasta/ && ./scripts/InstallPrerequisites-Ubuntu.sh
# RUN cd /root/shasta/ && mkdir shasta-build && cd shasta-build && cmake ../shasta && make all -j && make install

# Lumpy
RUN apt install -y build-essential
RUN cd /root && git clone --recursive https://github.com/arq5x/lumpy-sv.git
RUN cd /root/lumpy-sv && make && cp bin/* /usr/local/bin/.

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
COPY getty-noclear.conf getty-override.conf /etc/systemd/system/getty@tty1.service.d/
COPY getty-autologin-serial.conf /etc/systemd/system/serial-getty@ttyS0.service.d/
COPY logind.conf /etc/systemd/logind.conf
COPY boot-9p /etc/initramfs-tools/scripts/boot-9p

# this needs to be commented out in order to boot from hdd
RUN printf '%s\n' 9p 9pnet 9pnet_virtio virtio virtio_ring virtio_pci | tee -a /etc/initramfs-tools/modules && \
    echo 'BOOT=boot-9p' | tee -a /etc/initramfs-tools/initramfs.conf && \
    update-initramfs -u

RUN apt-get --yes clean && \
    rm -r /var/lib/apt/lists/* && \
    rm -r /usr/share/doc/* && \
    rm -r /usr/share/man/* && \
    rm -r /usr/share/locale/?? && \
    rm /var/log/*.log /var/log/lastlog /var/log/wtmp /var/log/apt/*.log /var/log/apt/*.xz
