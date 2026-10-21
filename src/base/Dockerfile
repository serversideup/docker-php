# syntax=docker/dockerfile:1
#
# Base image the variations can build FROM instead of the official php image. It
# compiles PHP from the php.net release tarball, so a new PHP release does not wait
# on Docker Hub. It is a port of docker-library/php's Dockerfile-linux.template
# (https://github.com/docker-library/php, MIT) with the template conditionals turned
# into build args and shell conditionals, and it keeps the official image's contract:
# paths, ENV, helper scripts, configure flags, and FPM configuration.
# scripts/test-base-image.sh checks that contract against the official image.
#
# The build context is the project root. The build args come from
# scripts/get-php-source.sh (scripts/dev.sh --variation base passes them all):
#   BASE_IMAGE    debian:bookworm-slim, debian:trixie-slim, alpine:3.22, alpine:3.23, alpine:3.24
#   OS_FAMILY     debian or alpine (derived from BASE_IMAGE; set it when using a registry mirror)
#   PHP_SAPI      cli, fpm, or zts
#   PHP_VERSION, PHP_URL, PHP_ASC_URL, PHP_SHA256, GPG_KEYS
#   PHP_BUILD_PROVIDER  reported by phpinfo() as "Build Provider"

ARG BASE_IMAGE=debian:bookworm-slim
ARG OS_FAMILY=${BASE_IMAGE%%:*}
ARG PHP_SAPI=cli

##########
# Debian base
##########
FROM ${BASE_IMAGE} AS base-debian

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -eux; \
	{ \
		echo 'Package: php*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-php

# dependencies required for running "phpize"
# (see persistent deps below)
ENV PHPIZE_DEPS="autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c"

# persistent / runtime deps
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
		ca-certificates \
		curl \
		xz-utils \
	; \
	if grep -q '^VERSION_CODENAME=bookworm' /etc/os-release; then rm -rf /var/lib/apt/lists/*; else apt-get dist-clean; fi

##########
# Alpine base
##########
FROM ${BASE_IMAGE} AS base-alpine

# dependencies required for running "phpize"
# these get automatically installed and removed by "docker-php-ext-*" (unless they're already installed)
ENV PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c"

# persistent / runtime deps
RUN apk add --no-cache \
		ca-certificates \
		curl \
		openssl \
		tar \
		xz

# ensure www-data user exists
# 82 is the standard uid/gid for "www-data" in Alpine
# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.14-stable
RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data

##########
# PHP build (shared by every OS and SAPI)
##########
# hadolint ignore=DL3006
FROM base-${OS_FAMILY} AS php

ENV PHP_INI_DIR=/usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ARG GPG_KEYS
ARG PHP_VERSION
ARG PHP_URL
ARG PHP_ASC_URL
ARG PHP_SHA256
ENV GPG_KEYS="${GPG_KEYS}"
ENV PHP_VERSION="${PHP_VERSION}"
ENV PHP_URL="${PHP_URL}" PHP_ASC_URL="${PHP_ASC_URL}"
ENV PHP_SHA256="${PHP_SHA256}"

# The download helper is mounted for the build only, so it does not end up in the image.
# Unquoted lists ($GPG_KEYS, $savedAptMark) are split into words on purpose, as upstream does.
# hadolint ignore=DL3003,SC2086
RUN --mount=type=bind,source=src/common/usr/local/bin/docker-php-serversideup-download,target=/usr/local/bin/docker-php-serversideup-download \
	set -eux; \
	for var in PHP_VERSION PHP_URL PHP_ASC_URL PHP_SHA256 GPG_KEYS; do \
		eval "value=\${$var}"; \
		if [ -z "$value" ]; then echo >&2 "error: build arg $var is required (see scripts/get-php-source.sh)"; exit 1; fi; \
	done; \
	\
	if [ -f /etc/alpine-release ]; then \
		apk add --no-cache --virtual .fetch-deps gnupg; \
	else \
		savedAptMark="$(apt-mark showmanual)"; \
		apt-get update; \
		apt-get install -y --no-install-recommends gnupg; \
		if grep -q '^VERSION_CODENAME=bookworm' /etc/os-release; then rm -rf /var/lib/apt/lists/*; else apt-get dist-clean; fi; \
	fi; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	docker-php-serversideup-download "$PHP_URL" php.tar.xz; \
	echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	\
	docker-php-serversideup-download "$PHP_ASC_URL" php.tar.xz.asc; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		for attempt in 1 2 3 4 5; do \
			if gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; then break; fi; \
			if [ "$attempt" = 5 ]; then exit 1; fi; \
			sleep "$((attempt * 3))"; \
		done; \
	done; \
	gpg --batch --verify php.tar.xz.asc php.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	if [ -f /etc/alpine-release ]; then \
		apk del --no-network .fetch-deps; \
	else \
		apt-mark auto '.*' > /dev/null; \
		apt-mark manual $savedAptMark > /dev/null; \
		apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	fi

COPY --chmod=755 src/base/bin/docker-php-source /usr/local/bin/

ARG PHP_SAPI
ARG PHP_BUILD_PROVIDER=https://github.com/serversideup/docker-php

# Unquoted lists ($patches, $runDeps, $savedAptMark) are split into words on purpose, as upstream does.
# hadolint ignore=DL3003,SC2086
RUN --mount=type=bind,source=src/common/usr/local/bin/docker-php-serversideup-download,target=/usr/local/bin/docker-php-serversideup-download \
	set -eux; \
	case "$PHP_SAPI" in \
		cli|fpm|zts) ;; \
		*) echo >&2 "error: PHP_SAPI must be cli, fpm, or zts (got '$PHP_SAPI')"; exit 1 ;; \
	esac; \
	if [ -f /etc/alpine-release ]; then os=alpine; else os=debian; fi; \
	\
# PHP_VERSION_ID as defined by https://www.php.net/phpversion ("8.6.0RC4" counts as 8.6.0)
	version="${PHP_VERSION%%[!0-9.]*}"; \
	major="${version%%.*}"; \
	rest="${version#*.}"; \
	minor="${rest%%.*}"; \
	patch="${rest#*.}"; \
	if [ "$patch" = "$rest" ]; then patch=0; fi; \
	versionId="$((major * 10000 + minor * 100 + patch))"; \
	minorVersion="$major.$minor"; \
	\
# https://github.com/docker-library/php/issues/1554 (pecl/pear and the oniguruma-backed mbstring are not built for 8.6+)
	installPearPecl=; \
	if [ "$versionId" -lt 80600 ]; then installPearPecl=1; fi; \
	\
# Alpine patches carried by docker-library/php: "<php-src commit> <sha256> <issue> <apply|reverse>"
# https://github.com/docker-library/php/pull/1552 (11678, 14834), https://github.com/docker-library/php/pull/1580 (18743),
# and https://github.com/docker-library/php/pull/1638 (19131 is reversed in 8.1.34 so that 14834 still applies)
	patches=; \
	if [ "$os" = alpine ] && [ "$minorVersion" = 8.1 ]; then \
		patches="577b8ae4226368e66fee7a9b5c58f9e2428372fc 6edc20c3bb3e7cc13515abce7f2fffa8ebea6cf7469abfbc78fcdc120350b239 11678 apply"; \
		if [ "$versionId" -ge 80134 ]; then \
			patches="$patches a5df26691d1b1f71b964b869510473a5d5413999 c98c01c74d3a6da197116f8511b16fed361ca6bbb6a8af8df629a933f541c213 19131 reverse"; \
		fi; \
		patches="$patches 67259e451d5d58b4842776c5696a66d74e157609 ed10a1b254091ad676ed204e55628ecbd6c8962004d6185a1821cedecd526c0f 14834 apply"; \
		if [ "$PHP_SAPI" = zts ]; then \
			patches="$patches 6b105d4bc57e20a2472c9a6ff11fba32768556d4 037e1610ae5d444e9a8c3ecd9d5f0cd215fd0aac90bdd7b9f0b259bffdf3566b 18743 apply"; \
		fi; \
	elif [ "$os" = alpine ] && [ "$minorVersion" = 8.2 ] && [ "$PHP_SAPI" = zts ]; then \
		patches="b3c8afe272a6919248986c703c2e1defc73ff707 b334f73434c9732a4b27a42eb5d417e10df842e854c02a3e753b2479f8978bf5 18743 apply"; \
	fi; \
	\
	if [ "$os" = alpine ]; then \
		apk add --no-cache --virtual .build-deps \
			$PHPIZE_DEPS \
			argon2-dev \
			coreutils \
			curl-dev \
			gnu-libiconv-dev \
			libsodium-dev \
			libxml2-dev \
			linux-headers \
			openssl-dev \
			readline-dev \
			sqlite-dev \
			${installPearPecl:+oniguruma-dev} \
			${patches:+patch patchutils} \
		; \
# make sure musl's iconv doesn't get used (https://www.php.net/manual/en/intro.iconv.php)
		rm -vf /usr/include/iconv.h; \
	else \
		savedAptMark="$(apt-mark showmanual)"; \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			libargon2-dev \
			libcurl4-openssl-dev \
			libreadline-dev \
			libsodium-dev \
			libsqlite3-dev \
			libssl-dev \
			libxml2-dev \
			zlib1g-dev \
			${installPearPecl:+libonig-dev} \
		; \
	fi; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
# https://github.com/php/php-src/blob/d6299206dd828382753453befd1b915491b741c6/configure.ac#L1496-L1511
		PHP_BUILD_PROVIDER="$PHP_BUILD_PROVIDER" \
		PHP_UNAME='Linux - Docker' \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	set -- $patches; \
	while [ "$#" -ge 4 ]; do \
		docker-php-serversideup-download "https://github.com/php/php-src/commit/$1.patch?full_index=1" "$3.patch"; \
		echo "$2 *$3.patch" | sha256sum -c -; \
		if [ "$4" = reverse ]; then \
			patch --reverse -p1 < "$3.patch"; \
		else \
			filterdiff -x '*/NEWS' "$3.patch" | patch -p1; \
		fi; \
		rm "$3.patch"; \
		shift 4; \
	done; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	if [ "$os" = debian ]; then \
		debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
# https://bugs.php.net/bug.php?id=74125
		if [ ! -d /usr/include/curl ]; then \
			ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
		fi; \
	fi; \
	case "$gnuArch" in \
		'i686-linux-'*) \
# php zend jit assumes SSE registers, xmm0-7, are available (and "Pentium4"/SSE2 is a reasonable baseline)
# https://github.com/php/php-src/pull/22832
			export \
				CFLAGS="$CFLAGS -msse2 -mfpmath=sse" \
				CPPFLAGS="$CPPFLAGS -msse2 -mfpmath=sse" \
			; \
			;; \
	esac; \
	test "$PHP_INI_DIR" != "${PHP_INI_DIR%/php}"; \
	\
	set -- \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
# make sure invalid --configure-flags are fatal errors instead of just warnings
		--enable-option-checking=fatal \
# https://github.com/docker-library/php/issues/439
		--with-mhash \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash
		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
		--with-sodium=shared \
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		--with-curl \
		--with-openssl \
		--with-readline \
		--with-zlib \
	; \
# https://github.com/docker-library/php/pull/1636 (the official 8.1 images predate it; the value is configure's default either way)
	if [ "$minorVersion" != 8.1 ]; then set -- "$@" --sysconfdir="${PHP_INI_DIR%/php}"; fi; \
# https://github.com/docker-library/php/issues/822
# 8.6+: no --enable-pic; forcing PIC also removes -fpie from executable objects, preventing local-exec TLS: https://github.com/docker-library/php/pull/1692
	if [ "$versionId" -lt 80600 ]; then set -- "$@" --with-pic; fi; \
# --enable-ftp is included for compatibility with existing versions (https://github.com/docker-library/php/issues/236)
	if [ "$minorVersion" = 8.1 ]; then set -- "$@" --enable-ftp; fi; \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
	if [ -n "$installPearPecl" ]; then set -- "$@" --enable-mbstring --with-pear; fi; \
	if [ "$os" = alpine ]; then \
		set -- "$@" --with-iconv=/usr; \
	else \
		set -- "$@" --with-iconv --with-libdir="lib/$debMultiarch"; \
	fi; \
	case "$PHP_SAPI" in \
# https://github.com/docker-library/php/pull/1259
		cli|zts) set -- "$@" --enable-phpdbg --enable-phpdbg-readline ;; \
# https://github.com/bwoebi/phpdbg-docs/issues/1#issuecomment-163872806 ("phpdbg is primarily a CLI debugger, and is not suitable for debugging an fpm stack.")
		*) set -- "$@" --disable-phpdbg ;; \
	esac; \
# bundled pcre does not support JIT on riscv64 until 10.41 (php 8.3+)
	case "$minorVersion:$gnuArch" in \
		8.1:riscv64-linux-*|8.2:riscv64-linux-*) set -- "$@" --without-pcre-jit ;; \
	esac; \
# https://github.com/docker-library/php/issues/280
	if [ "$PHP_SAPI" = fpm ]; then set -- "$@" --disable-cgi; fi; \
# https://github.com/docker-library/php/pull/939#issuecomment-730501748
# zts + alpine special cased for embed (otherwise zts is effectively cli): https://github.com/docker-library/php/pull/1342
	if [ "$PHP_SAPI" = zts ] || { [ "$PHP_SAPI" = cli ] && { [ "$versionId" -ge 80600 ] || [ "$os" != alpine ]; }; }; then \
		set -- "$@" --enable-embed; \
	fi; \
	if [ "$PHP_SAPI" = fpm ]; then \
		set -- "$@" --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data; \
	fi; \
# https://externals.io/message/118859
	if [ "$PHP_SAPI" = zts ] || [ "$versionId" -ge 80600 ]; then \
		set -- "$@" --enable-zts --disable-zend-signals; \
		case "$minorVersion" in 8.1|8.2) set -- "$@" --enable-zend-max-execution-timers ;; esac; \
	fi; \
	./configure "$@"; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
	if [ "$os" = alpine ]; then \
		runDeps="$( \
			scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
				| tr ',' '\n' \
				| sort -u \
				| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		)"; \
		apk add --no-cache $runDeps; \
		apk del --no-network .build-deps; \
	else \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
		apt-mark auto '.*' > /dev/null; \
		[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
		find /usr/local -type f -executable -exec ldd '{}' ';' \
			| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
			| sort -u \
			| xargs -rt dpkg-query --search \
			| awk 'sub(":$", "", $1) { print $1 }' \
			| sort -u \
			| xargs -r apt-mark manual \
		; \
		apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
		if grep -q '^VERSION_CODENAME=bookworm' /etc/os-release; then rm -rf /var/lib/apt/lists/*; else apt-get dist-clean; fi; \
	fi; \
	\
	if [ -n "$installPearPecl" ]; then \
# update pecl channel definitions https://github.com/docker-library/php/issues/443
		pecl update-channels; \
		rm -rf /tmp/pear ~/.pearrc; \
	fi; \
	\
# smoke test
	php --version

COPY --chmod=755 src/base/bin/docker-php-ext-configure src/base/bin/docker-php-ext-enable src/base/bin/docker-php-ext-install src/base/bin/docker-php-entrypoint /usr/local/bin/

# enable OPcache by default before 8.5, where it became a required built-in (https://wiki.php.net/rfc/make_opcache_required)
# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN set -eux; \
	if [ "$(php -r 'echo PHP_VERSION_ID;')" -lt 80500 ]; then docker-php-ext-enable opcache; fi; \
	docker-php-ext-enable sodium

ENTRYPOINT ["docker-php-entrypoint"]

##########
# SAPI stages
##########
FROM php AS sapi-cli
CMD ["php", "-a"]

FROM php AS sapi-zts
CMD ["php", "-a"]

FROM php AS sapi-fpm
WORKDIR /var/www/html

# The official 8.1 images predate https://github.com/docker-library/php/pull/1636 and keep the
# older layout: no --sysconfdir (so "NONE/" is stripped from the include), the localhost listen
# line left in www.conf, and "listen = 9000" in zz-docker.conf instead of docker.conf.
# hadolint ignore=DL3003
RUN set -eux; \
	cd "${PHP_INI_DIR%/php}"; \
	legacyLayout=; \
	if [ "$(php -r 'echo PHP_VERSION_ID;')" -lt 80200 ]; then legacyLayout=1; fi; \
	\
	if [ -n "$legacyLayout" ]; then \
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		cp -v php-fpm.conf.default php-fpm.conf; \
		cp -v php-fpm.d/www.conf.default php-fpm.d/www.conf; \
		\
		# comment out localhost-only listen address
		grep -E '^listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
		sed -ri 's/^(listen = 127.0.0.1:9000)/;\1/' php-fpm.d/www.conf; \
		grep -E '^;listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
	fi; \
	\
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
		if [ -z "$legacyLayout" ]; then \
			echo; \
			echo '; default listen address for easy override in later php-fpm.d/*.conf files'; \
			echo 'listen = 9000'; \
		fi; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		if [ -n "$legacyLayout" ]; then \
			echo; \
			echo '[www]'; \
			echo 'listen = 9000'; \
		elif [ "$(php -r 'echo PHP_VERSION_ID;')" -lt 80600 ]; then \
			echo; \
			echo '; the [www] ini section below is for backwards compatibility and will be removed in 8.6+'; \
			echo '[www]'; \
		fi; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/docker-fpm.ini"

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]

##########
# Final image
##########
# hadolint ignore=DL3006
FROM sapi-${PHP_SAPI}
ARG PHP_BUILD_PROVIDER
LABEL org.opencontainers.image.title="serversideup/php-base" \
	org.opencontainers.image.description="PHP compiled from the php.net release tarball, compatible with the official php Docker images. The base for serversideup/php." \
	org.opencontainers.image.source="${PHP_BUILD_PROVIDER}" \
	org.opencontainers.image.version="${PHP_VERSION}"
