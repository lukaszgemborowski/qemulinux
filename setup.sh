#!/bin/bash

QEMU_URL="http://wiki.qemu-project.org/download/qemu-2.5.1.tar.bz2"
BUILDROOT_URL="https://buildroot.org/downloads/buildroot-2016.05.tar.bz2"

QEMU_PKG="qemu-2.5.1.tar.bz2"
BUILDROOT_PKG="buildroot-2016.05.tar.bz2"

function prepare_dirs {
	mkdir -p srcdir
	mkdir -p src
	mkdir -p tmp/qemu
        mkdir -p tmp/initramfs
}

function download_all {
	cd srcdir
	if [ ! -f ${QEMU_PKG} ]; then wget ${QEMU_URL}; fi
	if [ ! -f ${BUILDROOT_PKG} ]; then wget ${BUILDROOT_URL}; fi
	cd ..
}

function unpack_all {
	cd src
        if [ ! -d "qemu" ]; then tar xvf ../srcdir/${QEMU_PKG} && mv qemu-2.5.1 qemu; fi
		if [ ! -d "buildroot" ]; then tar xvf ../srcdir/${BUILDROOT_PKG} && mv buildroot-2016.05 buildroot; fi
        cd ..
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

function build_system {
	mkdir -p tmp/buildroot
	cp buildroot.config tmp/buildroot/.config

	cd src/buildroot
	make O=../../tmp/buildroot
	cd -
}

function make_all {
        configure_qemu
        build_qemu
        build_system
}

function run_qemu {
        tmp/qemu/bin/qemu-system-arm -machine versatilepb -kernel tmp/buildroot/images/zImage \
                -initrd tmp/buildroot/images/rootfs.cpio -append "root=/dev/mem" \
                -dtb tmp/buildroot/images/versatile-pb.dtb \
                -serial stdio
}

prepare_dirs
download_all
unpack_all
