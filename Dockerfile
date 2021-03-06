FROM ryanwclark/alpine:3.13
LABEL maintainer="Ryan Clark (ryanwclark@yahoo.com)"

## Set Environment Variables
ENV MEMCACHED_VERSION=1.6.10 \
    ZABBIX_HOSTNAME=memcached-app

RUN set -x && \
	addgroup -S -g 11211 memcached && \
    adduser -S -D -H -u 11211 -G memcached -g "Memcached" memcached && \
	apk add -t .memcached-build-deps \
				autoconf \
				automake \
				ca-certificates \
				coreutils \
				cyrus-sasl-dev \
				dpkg-dev dpkg \
				gcc \
				git \
				libc-dev \
				libevent-dev \
				libseccomp-dev \
				linux-headers \
				make \
				musl-dev \
				openssl \
				perl \
				perl-test-harness-utils \
				tar \
		        && \
    \
#    apk add .memcached-run-deps \
#            python \
#            && \
    \
	git clone https://github.com/memcached/memcached /usr/src/memcached && \
	cd /usr/src/memcached && \
	git -C /usr/src/memcached checkout ${MEMCACHED_VERSION} && \
	./autogen.sh && \
	./configure \
		--build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
		--enable-sasl && \
	make -j "$(nproc)" && \
	make install && \
	cd / && \
	runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" && \
	apk add --virtual .memcached-rundeps $runDeps && \
	apk del .memcached-build-deps && \
    rm -rf /var/cache/apk/*	&& \
	rm -rf /usr/src/memcached && \
	memcached -V


### Add Folders
ADD /install /

## Networking Setup
EXPOSE 11211
