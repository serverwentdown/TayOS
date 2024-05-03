VERSION 0.8

FROM docker.io/library/alpine:3.19
WORKDIR /src

# Download common tools
RUN apk add --no-cache \
		alpine-sdk \
		xz

kernel-src:
	ARG major_version
	ARG version
	# Download kernel
	RUN wget -O linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v${major_version}.x/linux-${version}.tar.xz \
		&& tar --xz -xf linux.tar.xz \
		&& mv linux-${version} kernel
	WORKDIR kernel
	# Download tools
	RUN apk add --no-cache \
			ccache \
			perl \
			gmp-dev \
			mpc1-dev \
			mpfr-dev \
			elfutils-dev \
			flex \
			bison \
			zstd \
			linux-headers \
			openssl-dev \
			diffutils \
			findutils \
			ncurses-dev
	# Configure kernel
	COPY config .config

kernel-shell:
	ARG major_version=6
	ARG version=6.8.7
	FROM +kernel-src \
		--major_version=$major_version \
		--version=$version
	# Open a shell to poke around menuconfig
	RUN false

kernel:
	ARG major_version=6
	ARG version=6.8.7
	FROM +kernel-src \
		--major_version=$major_version \
		--version=$version
	# Build kernel
	CACHE --sharing=private /ccache
	ENV CCACHE_DIR=/ccache
	ENV KBUILD_BUILD_TIMESTAMP=0
	RUN ccache -s
	RUN export PATH="/usr/lib/ccache/bin:$PATH" \
		&& make -j$(nproc) \
			KBUILD_BUILD_VERSION=TayOS \
			bzImage
	RUN ccache -s
	# Export kernel
	SAVE ARTIFACT arch/x86/boot/bzImage vmlinuz

busybox:
	ARG version=1.36.1
	# Download BusyBox
	RUN wget -O busybox.tar.bz2 https://busybox.net/downloads/busybox-${version}.tar.bz2 \
		&& tar --bzip2 -xf busybox.tar.bz2 \
		&& mv busybox-${version} busybox
	WORKDIR busybox
	# Download tools
	RUN apk add --no-cache \
			linux-headers
	# Configure BusyBox
	RUN make defconfig
	RUN sed -i -r 's/^(CONFIG_STATIC=.*|# CONFIG_STATIC is not set)/CONFIG_STATIC=y/' .config
	# Build BusyBox
	RUN make -j$(nproc)
	RUN make install \
		# Remove unneeded BusyBox files
		&& rm -r \
			_install/linuxrc
	# Export BusyBox
	SAVE ARTIFACT _install/*

openssl:
	ARG version=3.3.0
	# Download OpenSSL
	RUN wget -O openssl.tar.gz https://www.openssl.org/source/openssl-${version}.tar.gz \
		&& tar --gzip -xf openssl.tar.gz \
		&& mv openssl-${version} openssl
	WORKDIR openssl
	# Download tools
	RUN apk add --no-cache \
			linux-headers \
			perl
	# Configure OpenSSL
	RUN ./Configure \
			linux-x86_64 \
			--prefix=/usr \
			--libdir=lib \
			--openssldir=/etc/ssl \
			-static \
			enable-ktls \
			#shared \
			no-docs \
			no-deprecated \
			no-zlib \
			no-async \
			no-comp \
			no-idea \
			no-mdc2 \
			no-rc5 \
			no-ec2m \
			no-ssl3 \
			no-seed \
			no-weak-ssl-ciphers \
			-Wa,--noexecstack
	# Build OpenSSL
	RUN make -j$(nproc)
	RUN make DESTDIR="_install" install \
		# Remove unneeded OpenSSL files
		&& rm -r \
			_install/usr/lib/cmake/ \
			_install/usr/lib/engines-3/ \
			_install/usr/lib/ossl-modules/ \
			_install/usr/lib/pkgconfig/ \
			#_install/usr/lib/*.so* \
			_install/usr/lib/*.a \
			_install/usr/include/ \
			_install/etc/ssl/misc/ \
			_install/etc/ssl/private/ \
			_install/etc/ssl/ct_log_list* \
			_install/etc/ssl/openssl.cnf.*
	# Export OpenSSL
	SAVE ARTIFACT _install/*

rootfs:
	RUN mkdir rootfs
	COPY +busybox/ rootfs/
	COPY +openssl/ rootfs/
	RUN mkdir -p rootfs/etc/ssl/certs rootfs/usr/share/ca-certificates \
		&& cp -R /etc/ssl/certs/* rootfs/etc/ssl/certs/ \
		&& cp -R /usr/share/ca-certificates/* rootfs/usr/share/ca-certificates/
	COPY rootfs/ rootfs/
	SAVE ARTIFACT rootfs/*

cpio:
	FROM +kernel
	COPY +rootfs/ rootfs/
	# Generate initramfs
	RUN ./usr/gen_initramfs.sh -o initramfs rootfs/
	SAVE ARTIFACT initramfs

all:
	COPY +kernel/vmlinuz .
	COPY +cpio/initramfs .
	SAVE ARTIFACT *

iso-efi:
	RUN apk add --no-cache \
			mtools \
			grub grub-efi
	# Create EFI boot partition image
	RUN mkdir -p efi/boot \
		&& echo -e 'search --no-floppy --set=root --label "tayos"\nset prefix=($root)/boot/grub' > grub_early.cfg \
		&& grub-mkimage \
			--config="grub_early.cfg" \
			--prefix="/boot/grub" \
			--output="efi/boot/bootx64.efi" \
			--format="x86_64-efi" \
			--compression="xz" \
			all_video disk part_gpt part_msdos \
			linux normal configfile search search_label \
			efi_gop fat iso9660 cat echo ls test true help gzio \
		&& mformat -i efi.img -C -f 1440 -N 0 :: \
		&& mcopy -i efi.img -s efi ::
	SAVE ARTIFACT efi.img

iso:
	RUN apk add --no-cache \
			xorriso
	# Copy in ISO EFI image
	COPY +iso-efi/efi.img isoroot/boot/grub/efi.img
	# Copy in GRUB configuration
	COPY grub.cfg isoroot/boot/grub/grub.cfg
	# Copy in kernel and initramfs
	COPY +kernel/vmlinuz isoroot/boot/
	COPY +cpio/initramfs isoroot/boot/
	# Build iso
	RUN xorrisofs \
			-output tayos.iso \
			-full-iso9660-filenames \
			-joliet \
			-rational-rock \
			-sysid LINUX \
			-volid "tayos" \
			\
			-eltorito-alt-boot \
			-e boot/grub/efi.img \
			-no-emul-boot \
			-isohybrid-gpt-basdat \
			\
			-follow-links \
			isoroot
	SAVE ARTIFACT tayos.iso

test-qemu-iso:
	RUN apk add --no-cache \
			qemu qemu-system-x86_64 \
			ovmf
	COPY +iso/tayos.iso .
	RUN qemu-system-x86_64 -machine q35 -bios /usr/share/ovmf/bios.bin -m 512M -nic user -boot d -cdrom tayos.iso
	# On Fedora:
	#   qemu-system-x86_64 -machine q35 -bios /usr/share/OVMF/OVMF_CODE.fd -m 512M -nic user -boot d -cdrom tayos.iso
