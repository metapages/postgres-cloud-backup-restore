FROM alpine:3.15

# This is already the default, but making it explicit for clarity
USER root

####################################################################################################################
# base requirements plus postgresql-client
RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
        libcap \
        bash \
        ca-certificates \
        curl \
        postgresql-client
####################################################################################################################

####################################################################################################################
# rclone from https://github.com/justintien/docker-rclone-alpine/blob/master/Dockerfile
# https://rclone.org/
ENV RCLONE_VERSION=1.57.0
ENV ARCH=amd64
RUN apk update \
    && apk add \
        openssl \
        ca-certificates \
        fuse \
    && cd /tmp \
    && wget -q https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-${ARCH}.zip \
    && unzip /tmp/rclone-v${RCLONE_VERSION}-linux-${ARCH}.zip \
    && mv /tmp/rclone-*-linux-${ARCH}/rclone /usr/bin \
    && rm -r /tmp/rclone*
####################################################################################################################

####################################################################################################################
# supercronic (better cron)
# https://github.com/Cethy/alpine-supercronic/blob/master/Dockerfile
ENV SUPERCRONIC_VERSION="v0.1.3" \
    SUPERCRONIC_PACKAGE=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=96960ba3207756bb01e6892c978264e5362e117e
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC_PACKAGE
# install dependencies
RUN apk add --update --no-cache ca-certificates curl \
# install supercronic
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC_PACKAGE}" | sha1sum -c - \
    && chmod +x "${SUPERCRONIC_PACKAGE}" \
    && mv "${SUPERCRONIC_PACKAGE}" "/bin/${SUPERCRONIC_PACKAGE}" \
    && ln -s "/bin/${SUPERCRONIC_PACKAGE}" /bin/supercronic \
# remove unwanted deps & cleanup
    && rm -rf /tmp/* /var/cache/apk/*
####################################################################################################################

####################################################################################################################
# justfile for running commands, you will mostly interact with just https://github.com/casey/just
RUN apk add --update --no-cache ca-certificates curl ;\
    VERSION=1.0.0 ; \
    SHA256SUM=342f8582d929b9212ffcbe9f7749e12908053cf215eb8d4a965c47ea2f24b0a4 ; \
    curl -L -O https://github.com/casey/just/releases/download/$VERSION/just-$VERSION-x86_64-unknown-linux-musl.tar.gz && \
    (echo "$SHA256SUM  just-$VERSION-x86_64-unknown-linux-musl.tar.gz" | sha256sum -c -) && \
    mkdir -p /usr/local/bin && \
    tar -xzf just-$VERSION-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin just && \
    rm -rf just-$VERSION-x86_64-unknown-linux-musl.tar.gz && \
    rm -rf /tmp/* /var/cache/apk/*
# just tweak: unify the just binary location on host and container platforms because otherwise the shebang doesn't work properly due to no string token parsing (it gets one giant string)
ENV PATH $PATH:/usr/local/bin
# alias "j" to just, it's just right there index finger
RUN echo -e '#!/bin/bash\njust "$@"' > /usr/bin/j && \
    chmod +x /usr/bin/j
####################################################################################################################

####################################################################################################################
# create and set a non-root user: justuser
# https://stackoverflow.com/questions/63046301/how-to-run-cron-as-non-root-in-alpine
RUN addgroup -S justuser && adduser -S justuser -G justuser
COPY --chown=justuser:justuser ./justfile /home/justuser/justfile
USER justuser
WORKDIR /home/justuser
ENTRYPOINT ["just"]

####################################################################################################################
# Bug in rclone/alpine/something: https://github.com/tynor88/docker-rclone/issues/19#issuecomment-655805740
# workaround:
ENV RCLONE_VERSION=true
