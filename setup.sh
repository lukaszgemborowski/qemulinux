#!/bin/bash

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.6.tar.xz"
QEMU_URL="http://wiki.qemu-project.org/download/qemu-2.5.1.tar.bz2"
BUSYBOX_URL="http://sources.openelec.tv/mirror/busybox/busybox-1.24.1.tar.bz2"

LINUX_PKG="linux-4.4.6.tar.xz"
QEMU_PKG="qemu-2.5.1.tar.bz2"
BUSYBOX_PKG="busybox-1.24.1.tar.bz2"

if [ -z "$CC_PREFIX" ]
then
    unset CC_PREFIX
    export CC_PREFIX="/usr/bin/arm-linux-gnueabi-"
    echo "using default CC_PREFIX=$CC_PREFIX"
else
    echo "using provided CC_PREFIX=$CC_PREFIX"
    cctmp=$CC_PREFIX
    unset CC_PREFIX
    export CC_PREFIX=$cctmp
fi

function prepare_dirs {
	mkdir -p srcdir
	mkdir -p src
	mkdir -p tmp/linux
	mkdir -p tmp/busybox
	mkdir -p tmp/qemu
        mkdir -p tmp/initramfs
}

function download_all {
	cd srcdir
	if [ ! -f ${LINUX_PKG} ]; then wget ${KERNEL_URL}; fi
	if [ ! -f ${QEMU_PKG} ]; then wget ${QEMU_URL}; fi
	if [ ! -f ${BUSYBOX_PKG} ]; then wget ${BUSYBOX_URL}; fi
	cd ..
}

function unpack_all {
	cd src
	if [ ! -d "linux" ]; then tar xvf ../srcdir/${LINUX_PKG} && mv linux-4.4.6 linux; fi
        if [ ! -d "busybox" ]; then tar xvf ../srcdir/${BUSYBOX_PKG} && mv busybox-1.24.1 busybox; fi
        if [ ! -d "qemu" ]; then tar xvf ../srcdir/${QEMU_PKG} && mv qemu-2.5.1 qemu; fi
        cd ..
}

function build_linux {
        cd src/linux
	make O=../../tmp/linux ARCH=arm CROSS_COMPILE=$CC_PREFIX -j8
        cd -
}

function menuconfig_linux {
        cd src/linux
        make O=../../tmp/linux ARCH=arm menuconfig
        cd -
}

function configure_linux {
        cp config tmp/linux/.config
}

function configure_busybox {
        cd src/busybox
        make defconfig O=../../tmp/busybox ARCH=arm CROSS_COMPILE=$CC_PREFIX
        echo "CONFIG_STATIC=y" >> ../../tmp/busybox/.config
        cd -
}

function build_busybox {
        cd src/busybox
        make install -j8 O=../../tmp/busybox ARCH=arm CROSS_COMPILE=$CC_PREFIX
        cd -
}

function configure_qemu {
        cd src/qemu
        ./configure --prefix=$(pwd)/../../tmp/qemu --target-list=arm-softmmu
        cd -
}

function build_qemu {
        cd src/qemu
        make -j8
        make install
        cd -
}

function build_initramfs {
        cd tmp/initramfs
        mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
        cp ../../init .
        chmod +x init
        cp -av ../../tmp/busybox/_install/* .
        find . -print0 \
             | cpio --null -ov --format=newc \
             | gzip -9 > ../initramfs.cpio.gz
        cd -
}



function make_all {
        configure_linux
        configure_busybox
        configure_qemu

        build_linux
        build_busybox
        build_qemu
        build_initramfs
}

function run_qemu {
        tmp/qemu/bin/qemu-system-arm -machine versatilepb -kernel tmp/linux/arch/arm/boot/zImage \
                -initrd tmp/initramfs.cpio.gz -append "root=/dev/mem" \
                -dtb tmp/linux/arch/arm/boot/dts/versatile-pb.dtb \
                -serial stdio
}


prepare_dirs
download_all
unpack_all

