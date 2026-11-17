FROM alpine:3.24

ARG TARGETARCH
ARG TARGETVARIANT

RUN apk add --no-cache bash gettext-envsubst

WORKDIR /opt/chirpstack

# The release tarballs call the 32-bit ARM build "armv7hf"; buildx calls it arm/v7.
RUN --mount=type=bind,from=dist,target=/dist \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      amd64) arch=amd64 ;; \
      arm64) arch=arm64 ;; \
      armv7) arch=armv7hf ;; \
      *) echo "unsupported platform: ${TARGETARCH}${TARGETVARIANT}" >&2; exit 1 ;; \
    esac; \
    set -- /dist/chirpstack-udp-forwarder_*_"${arch}".tar.gz; \
    if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then \
      echo "expected exactly one ${arch} tarball in the dist context, found: $*" >&2; exit 1; \
    fi; \
    tar -xzf "$1"

COPY runner/ ./

# The start script writes the configuration here; nothing else in the work
# directory is written at run time.
RUN mkdir run && chown nobody:nogroup run

USER nobody:nogroup
ENV PATH="${PATH}:/opt/chirpstack"
CMD ["bash", "start"]
