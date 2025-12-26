ARG CST_VERSION=latest
ARG CURRENT_VERSION_MICRO=latest

FROM ghcr.io/googlecontainertools/container-structure-test:$CST_VERSION AS container-structure-test

FROM docker:${CURRENT_VERSION_MICRO}-dind

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
ARG CURRENT_VERSION_MICRO
ARG DATE
ARG COMMIT
ARG AUTHOR

LABEL \
    org.opencontainers.image.created=$DATE \
    org.opencontainers.image.url="https://hub.docker.com/r/pfillion/dind" \
    org.opencontainers.image.source="https://github.com/pfillion/dind" \
    org.opencontainers.image.version=$CURRENT_VERSION_MICRO \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor="pfillion" \
    org.opencontainers.image.title="dind" \
    org.opencontainers.image.description="Docker in Docker with more tools" \
    org.opencontainers.image.authors=$AUTHOR \
    org.opencontainers.image.licenses="MIT"

COPY --from=container-structure-test /ko-app/container-structure-test ./bin/

RUN apk add --update --no-cache \
        git \
        make \
        bash \
        bats \
    ; \