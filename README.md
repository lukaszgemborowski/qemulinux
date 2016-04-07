# qemulinux
Utility script for building minimal Linux system (with busybox) running on qemu (arm)

# howto
## prerequisites
To build your Linux you need to have ARM cross compiler installed. On debian/ubuntu-like systems 
you should be able to simply install package gcc-arm-linux-gnueabi.

## usage
in simplest case you need just to source setup.sh script:
> source setup.sh

this will automatically download needed packages (linux, busybox, qemu) and unpack them. After that you can start build by:
> make_all

after while you should have everyting build in $(pwd)/tmp directory, to run your kernel type:
> run_qemu

## cross compiler custom location
if your cross compiler isn't in /usr/bin/arm-linux-gnueabi-gcc you need to set CC_PREFIX before sourcing the script, eg:
> CC_PREFIX=/opt/armcc/arm-linux-gnueabi- source setup.sh
