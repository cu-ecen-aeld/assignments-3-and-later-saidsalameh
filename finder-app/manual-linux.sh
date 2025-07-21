#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

export PATH=$PATH:$HOME/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-linux-gnu/bin


OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

current_path=$(pwd)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    echo 'Clean'
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    # defconfig
    echo 'defconfig'
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # build vmlinux
    echo 'build vmlinux'
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    # build modules
    echo 'build modules'
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    # build devicetree
    echo 'build devicetree'
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs  
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

echo "Creating the necessary base directories. "
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
echo "Creating the necessary base directories done. "



cd "$OUTDIR"
if [ -d "${OUTDIR}/busybox" ]; then
    echo "Removing existing busybox directory to avoid corruption"
    rm -rf busybox
fi

echo "Cloning BusyBox repository..."
git clone https://github.com/mirror/busybox.git busybox


cd busybox
git checkout ${BUSYBOX_VERSION}

echo "Configuring BusyBox..."
make distclean
make defconfig

echo "Building BusyBox..."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

echo "Installing BusyBox to rootfs..."
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd ${OUTDIR}/rootfs



echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

LD_SO=$(aarch64-none-linux-gnu-gcc -print-file-name=ld-linux-aarch64.so.1)
LIBC=$(aarch64-none-linux-gnu-gcc -print-file-name=libc.so.6)
LIBM=$(aarch64-none-linux-gnu-gcc -print-file-name=libm.so.6)
LIBRES=$(aarch64-none-linux-gnu-gcc -print-file-name=libresolv.so.2)

mkdir -p ${OUTDIR}/rootfs/lib
mkdir -p ${OUTDIR}/rootfs/lib64
cp ${LD_SO} ${OUTDIR}/rootfs/lib/
cp ${LIBC} ${OUTDIR}/rootfs/lib/
cp ${LIBM} ${OUTDIR}/rootfs/lib/
cp ${LIBRES} ${OUTDIR}/rootfs/lib/


# Copy the program interpreter (dynamic linker) to /lib
cp $(aarch64-none-linux-gnu-gcc -print-file-name=ld-linux-aarch64.so.1) ${OUTDIR}/rootfs/lib/

# Copy shared libraries to /lib64
cp $(aarch64-none-linux-gnu-gcc -print-file-name=libc.so.6) ${OUTDIR}/rootfs/lib64/
cp $(aarch64-none-linux-gnu-gcc -print-file-name=libm.so.6) ${OUTDIR}/rootfs/lib64/
cp $(aarch64-none-linux-gnu-gcc -print-file-name=libresolv.so.2) ${OUTDIR}/rootfs/lib64/





# TODO: Make device nodes

sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
 

# TODO: Clean and build the writer utility
cd ${current_path}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -a writer ${OUTDIR}/rootfs/home
cp -a finder.sh ${OUTDIR}/rootfs/home
cp -ar ../conf ${OUTDIR}/rootfs/home
cp -a finder-test.sh ${OUTDIR}/rootfs/home
cp -a autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
