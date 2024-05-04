VERSION 0.8

FROM docker.io/library/alpine:3.19
WORKDIR /src

# Download common tools
RUN apk add --no-cache \
		alpine-sdk \
		xz

kernel-src:
	ARG major_version=6
	ARG version=6.8.7
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
	# Download kernel
	RUN wget -O linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v${major_version}.x/linux-${version}.tar.xz \
		&& tar --xz -xf linux.tar.xz \
		&& mv linux-${version} kernel
	WORKDIR kernel
	# Configure kernel
	COPY config .config

kernel-menuconfig:
	FROM +kernel-src
	# Open a shell to poke around menuconfig
	RUN --interactive-keep make menuconfig
	SAVE ARTIFACT .config AS LOCAL config

kernel:
	FROM +kernel-src
	# Cache the kernel build
	CACHE --sharing=private /ccache
	ENV CCACHE_DIR=/ccache
	ENV PATH="/usr/lib/ccache/bin:$PATH"
	ENV KBUILD_BUILD_TIMESTAMP=0
	RUN ccache -s
	# Build kernel
	RUN make -j$(nproc) \
			KBUILD_BUILD_VERSION=TayOS \
			bzImage
	RUN ccache -s
	# Export kernel
	SAVE ARTIFACT arch/x86/boot/bzImage vmlinuz

busybox:
	ARG version=1.36.1
	# Download tools
	RUN apk add --no-cache \
			linux-headers
	# Download BusyBox
	RUN wget -O busybox.tar.bz2 https://busybox.net/downloads/busybox-${version}.tar.bz2 \
		&& tar --bzip2 -xf busybox.tar.bz2 \
		&& mv busybox-${version} busybox
	WORKDIR busybox
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
	# Download tools
	RUN apk add --no-cache \
			linux-headers \
			perl
	# Download OpenSSL
	RUN wget -O openssl.tar.gz https://www.openssl.org/source/openssl-${version}.tar.gz \
		&& tar --gzip -xf openssl.tar.gz \
		&& mv openssl-${version} openssl
	WORKDIR openssl
	# Configure OpenSSL
	RUN ./Configure \
			linux-x86_64 \
			--prefix=/usr \
			--libdir=lib \
			--openssldir=/etc/ssl \
			# Enable static linking
			-static \
			# Reduce disk usage
			no-afalgeng \
			no-argon2 \
			no-aria \
			no-autoerrinit \
			no-bf \
			no-blake2 \
			no-brotli \
			no-brotli-dynamic \
			no-camellia \
			no-capieng \
			no-winstore \
			no-cast \
			no-cmac \
			no-cmp \
			no-cms \
			no-ct \
			no-des \
			no-dgram \
			no-dsa \
			no-dso \
			no-dtls \
			no-dynamic-engine \
			no-ec_nistp_64_gcc_128 \
			no-ecx \
			no-egd \
			no-engine \
			no-fips \
			no-filenames \
			no-gost \
			no-http \
			no-legacy \
			no-loadereng \
			no-md2 \
			no-md4 \
			no-module \
			no-multiblock \
			no-nextprotoneg \
			no-ocb \
			no-ocsp \
			no-padlockeng \
			no-psk \
			no-quic \
			no-rc2 \
			no-rc4 \
			no-rdrand \
			no-rfc3779 \
			no-rmd160 \
			no-scrypt \
			no-sctp \
			no-secure-memory \
			no-shared \
			no-siphash \
			no-siv \
			no-sm2 \
			no-sm2-precomp \
			no-sm3 \
			no-sm4 \
			no-srp \
			no-srtp \
			no-static-engine \
			no-ssl-trace \
			no-tests \
			no-ts \
			no-ui-console \
			no-unit-test \
			no-whirlpool \
			no-zlib-dynamic \
			no-zstd \
			no-zstd-dynamic \
			# Continued standard arguments
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
	# Test OpenSSL
	RUN ls -l ./_install/usr/bin/openssl \
		&& ./_install/usr/bin/openssl 2>&1 \
		&& echo "GET /" | ./_install/usr/bin/openssl s_client google.com:443
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

kernel-and-initramfs:
	COPY +kernel/vmlinuz .
	COPY +cpio/initramfs .
	SAVE ARTIFACT *

iso-efi:
	# Download tools
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
	# Download tools
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

test-qemu-kernel:
	RUN apk add --no-cache \
			qemu qemu-system-x86_64 \
			ovmf
	COPY +kernel-and-initramfs/* .
	RUN --interactive qemu-system-x86_64 -machine q35 -m 512M -nic user -kernel vmlinuz -initrd initramfs -append 'console=ttyS0' -nographic

test-qemu-iso:
	RUN apk add --no-cache \
			qemu qemu-system-x86_64 \
			ovmf
	COPY +iso/tayos.iso .
	RUN --interactive qemu-system-x86_64 -machine q35 -m 512M -nic user -boot d -cdrom tayos.iso -bios /usr/share/ovmf/bios.bin -nographic
	# On Fedora:
	#   qemu-system-x86_64 -machine q35 -m 512M -nic user -boot d -cdrom tayos.iso -bios /usr/share/OVMF/OVMF_CODE.fd
