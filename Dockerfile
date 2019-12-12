FROM golang:alpine as builder

WORKDIR /go/src/github.com/dcu/mongodb_exporter

COPY shared ./shared
COPY snap ./snap
COPY collector ./collector
COPY mongodb_exporter.go glide.* ./

RUN apk --no-cache add curl git make perl \
    && export PATH=/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    && curl -s https://glide.sh/get -o /tmp/get \
    && sh /tmp/get \
    && glide install \
    && env GO15VENDOREXPERIMENT=1 \
        CGO_ENABLED=0 \
        GOOS=linux \
        GOARCH=amd64 \
    go build -o mongodb_exporter mongodb_exporter.go \
    && cp ./mongodb_exporter /mongodb_exporter \
    && mkdir /ttmp \
    && chown root:root /ttmp \
    && chmod 0775 /ttmp

FROM scratch

# MongoDB Exporter image for OpenShift Origin

LABEL io.k8s.description="MongoDB Prometheus Exporter." \
      io.k8s.display-name="MongoDB Exporter" \
      io.openshift.expose-services="9113:http" \
      io.openshift.tags="mongodb,exporter,prometheus" \
      io.openshift.non-scalable="true" \
      help="For more information visit https://github.com/Worteks/docker-mongoexporter" \
      maintainer="Samuel MARTIN MORO <faust64@gmail.com>" \
      version="1.0"

COPY --from=builder /mongodb_exporter /mongodb_exporter
COPY --from=builder /ttmp /tmp

ENTRYPOINT ["/mongodb_exporter"]
