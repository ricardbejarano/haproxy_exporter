FROM golang:1-alpine AS build

ARG VERSION="0.12.0"
ARG CHECKSUM="86df7ae6c1eac94a1f2a3d0d0e15e1490c420c2ab0d4614354a9fd2058af4092"

ADD https://github.com/prometheus/haproxy_exporter/archive/v$VERSION.tar.gz /tmp/haproxy_exporter.tar.gz

RUN [ "$(sha256sum /tmp/haproxy_exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add ca-certificates curl make && \
    tar -C /tmp -xf /tmp/haproxy_exporter.tar.gz && \
    mkdir -p /go/src/github.com/prometheus && \
    mv /tmp/haproxy_exporter-$VERSION /go/src/github.com/prometheus/haproxy_exporter && \
    cd /go/src/github.com/prometheus/haproxy_exporter && \
      make build

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/prometheus/haproxy_exporter/haproxy_exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd && \
    mkdir -p /rootfs/etc/ssl/certs && \
      cp /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9101/tcp
ENTRYPOINT ["/bin/haproxy_exporter"]
