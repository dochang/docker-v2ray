FROM golang:latest AS builder

ARG V2RAY_PKG=v2ray.com/core
ARG V2RAY_TAG=v4.22.1
ARG PREFIX=/usr/local
ARG CODENAME=user
ARG V2RAY_GIT_URL=https://github.com/v2ray/v2ray-core.git
ARG GEOIP_URL=https://github.com/v2ray/geoip/releases/download/202001260102/geoip.dat
ARG GEOSITE_URL=https://github.com/v2ray/domain-list-community/releases/download/202001261402/dlc.dat

ENV CGO_ENABLED=0

RUN export GOPATH=$(go env GOPATH) && \
        git clone $V2RAY_GIT_URL $GOPATH/src/$V2RAY_PKG && \
        cd $GOPATH/src/$V2RAY_PKG && \
        git checkout $V2RAY_TAG && \
        export BUILDNAME=$(date '+%Y%m%d-%H%M%S') && \
        export VERSIONTAG=$(git describe --tags) && \
        export LDFLAGS="-s -w -X v2ray.com/core.codename=${CODENAME} -X v2ray.com/core.build=${BUILDNAME} -X v2ray.com/core.version=${VERSIONTAG}" && \
        go get ./... && \
        go build -o $PREFIX/bin/v2ray -ldflags "$LDFLAGS" ./main && \
        go build -o $PREFIX/bin/v2ctl -tags confonly -ldflags "$LDFLAGS" ./infra/control/main && \
        install -d $PREFIX/share/v2ray && \
        curl --output $PREFIX/share/v2ray/geoip.dat $GEOIP_URL && \
        curl --output $PREFIX/share/v2ray/geosite.dat $GEOSITE_URL



FROM dochang/confd:latest
LABEL maintainer="dochang@gmail.com"

ENV V2RAY_LOCATION_ASSET=/usr/local/share/v2ray
ENV V2RAY_LOCATION_CONFIG=/etc/v2ray

RUN apk --no-cache add ca-certificates

COPY --from=builder /usr/local/bin/v2* /usr/local/bin/
COPY --from=builder /usr/local/share/v2ray /usr/local/share/

VOLUME ["/etc/v2ray"]

CMD ["v2ray"]
