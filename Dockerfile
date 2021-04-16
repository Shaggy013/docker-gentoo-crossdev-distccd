FROM gentoo/stage3-amd64
#FROM necrose99/docker-gentoo-websync
    #echo 'PYTHON_TARGETS="${PYTHON_TARGETS} python2_7"' >> /etc/portage/make.conf && \
    #echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf && \
MAINTAINER necrose99 <necrose99@gmail.com>
RUN touch /etc/init.d/functions.sh && \
    echo 'EMERGE_DEFAULT_OPTS="--ask=n --jobs=8"' >> /etc/portage/make.conf && \
    echo 'GENTOO_MIRRORS="http://gentoo.osuosl.org/ http://mirrors.evowise.com/gentoo/"' >> /etc/portage/make.conf \
    echo 'COMMON_FLAGS="-march=znver2"' >> /etc/portage/make.conf
RUN mkdir -p /etc/portage/repos.conf \
&&  ( \
    echo '[gentoo]'  && \
    echo 'location = /var/db/repos/gentoo' && \
    echo 'sync-type = rsync' && \
    echo 'sync-uri = rsync://rsync.us.gentoo.org/gentoo-portage/' && \
    echo 'auto-sync = yes' \
    )> /etc/portage/repos.conf/gentoo.conf \
&&  mkdir -p /var/db/repos/gentoo/{distfiles,metadata,packages} \
&&  chown -R portage:portage /var/db/repos/gentoo \
&&  echo "masters = gentoo" > /var/db/repos/gentoo/metadata/layout.conf \
&&  emerge-webrsync -q \
&&  eselect news read new \
&&  env-update \
&&  rm /sbin/unix_chkpwd \
&& emerge crossdev sys-libs/db sys-libs/pam sys-apps/iproute2 dev-lang/perl \
    sys-libs/binutils-libs \
    # helps to save time for building later image ## add zeroconf/avahi for automagical networking friendlyness. 
&& USE="${USE} crossdev zeroconf ipv6" emerge distcc \
&&  mkdir -p /var/db/repos/portage-crossdev/{profiles,metadata} && \
    echo 'crossdev' > /var/db/repos/portage-crossdev/profiles/repo_name && \
    echo 'masters = gentoo' > /var/db/repos/portage-crossdev/metadata/layout.conf && \
    chown -R portage:portage /var/db/repos/portage-crossdev \
&& ( \
    echo "[crossdev]" && \
    echo "location = /var/db/repos/portage-crossdev" && \
    echo "priority = 10" && \
    echo "masters = gentoo" && \
    echo "auto-sync = no" \
    ) > /etc/portage/repos.conf/crossdev.conf \
&&  ( \
    echo "#!/bin/sh" && \
    echo "eval \"\`gcc-config -E\`\"" && \
    echo "exec distccd \"\$@\"" \
    ) > /usr/local/sbin/distccd-launcher && \
    chmod +x /usr/local/sbin/distccd-launcher \
&& emerge ccache && \
    echo 'FEATURES="ccache"' >> /etc/portage/make.conf && \
    echo 'CCACHE_SIZE="2G"' >> /etc/portage/make.conf && \
    echo 'CCACHE_MAXSIZE="2G"' >> /etc/portage/make.conf && \
    echo 'CCACHE_DIR="/var/tmp/portage/ccache"' >> /etc/portage/make.conf && \
    echo 'CCACHE_TEMPDIR="/var/tmp/portage/ccache"' >> /etc/portage/make.conf \
	## mutitarget xen likes, makes crossdev offten build more  cleanly 
&& USE="gold multitarget plugins " emerge -f binutils gcc linux-headers glibc gox \
&& USE="llvm_targets_AArch64 llvm_targets_RISCV llvm_targets_AMDGPU llvm_targets_ARM llvm_targets_NVPTX llvm_targets_WebAssembly gold ncurses xar"  emerge -f llvm clang rust\
&& crossdev --b '~2.35.1' --g '~10.2.0' --k '~5.11' --l '~2.32' -t aarch64-unknown-linux-gnu --init-target -oO /var/db/repos/portage-crossdev \
&& echo "cross-aarch64-unknown-linux-gnu/gcc cxx multilib fortran -mudflap nls openmp -sanitize -vtv" >> /etc/portage/package.use/crossdev \
&& crossdev --stable -t aarch64-unknown-linux-gnu -oO /var/db/repos/portage-crossdev \
## place for the 4th pass extra pkgs. 
## && crossdev --stable -t aarch64-unknown-linux-gnu -oO /var/db/repos/portage-crossdev \
&& cd /usr/aarch64-unknown-linux-gnu/etc/portage \
&& rm -f make.profile \
&& ln -s /var/db/repos/gentoo/profiles/default/linux/arm64/17.0/desktop make.profile \
&& echo 'CHOST="aarch64-unknown-linux-gnu"' >> /etc/portage/make.conf \
&& gcc-config aarch64-unknown-linux-gnu-10.2.0\
&&  rm -r /var/db/repos/gentoo
#RUN echo 'CHOST="aarch64-unknown-linux-gnu-7.3.0"' >> /etc/portage/make.conf
#RUN gcc-config aarch64-unknown-linux-gnu-gcc
#RUN bash -c 'source /etc/profile &&  gcc-config  -l'
# for rpi1
#RUN crossdev -S -v -t armv6j-hardfloat-linux-gnueabi
#RUN emerge-webrsync
#RUN mkdir -pv /var/db/repos/portage-crossdev
#RUN grep CHOST /etc/portage/make.conf
#RUN ls /var/db/repos/portage-crossdev
#RUN ls /etc/env.d/gcc/
#RUN aarch64-unknown-linux-gnu-gcc --version
#avahi-daemon EXPOSE 5353
EXPOSE 5353 
EXPOSE 3632
RUN rc-service avahi-daemon start
CMD ["/usr/local/sbin/distccd-launcher", "--allow", "0.0.0.0/0", "--user", "distcc", "--log-level", "notice", "--log-stderr", "--no-detach"]
