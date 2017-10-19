FROM alpine:3.3

ENV OAUTH2_PROXY_REPO bitly/oauth2_proxy
ENV OAUTH2_PROXY_COMMIT 7b26256df62d0d00993433105794d2f23d8c27e4

RUN set -ex \
    \
    && export GOLANG_VERSION=1.9 \
    && export GOLANG_SRC_URL=https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz \
    && export GOLANG_SRC_SHA256=a4ab229028ed167ba1986825751463605264e44868362ca8e7accc8be057e993 \
    \
    && export GOLANG_BOOTSTRAP_VERSION=1.4.3 \
    && export GOLANG_BOOTSTRAP_URL=https://golang.org/dl/go$GOLANG_BOOTSTRAP_VERSION.src.tar.gz \
    && export GOLANG_BOOTSTRAP_SHA1=486db10dc571a55c8d795365070f66d343458c48 \
    \
    && apk add --no-cache --virtual .build-deps \
        bash \
        ca-certificates \
        gcc \
        musl-dev \
        openssl \
        tar \
        git \
        patch \
    && mkdir -p /usr/local/bootstrap \
    && wget -q "$GOLANG_BOOTSTRAP_URL" -O golang.tar.gz \
    && echo "$GOLANG_BOOTSTRAP_SHA1  golang.tar.gz" | sha1sum -c - \
    && tar -C /usr/local/bootstrap -xzf golang.tar.gz \
    && rm golang.tar.gz \
    && cd /usr/local/bootstrap/go/src \
    && ./make.bash \
    && export GOROOT_BOOTSTRAP=/usr/local/bootstrap/go \
    \
    && wget -q "$GOLANG_SRC_URL" -O golang.tar.gz \
    && echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz \
    && cd /usr/local/go/src \
    && ./make.bash \
    \
    && rm -rf /usr/local/bootstrap /usr/local/go/pkg/bootstrap \
    \
    && mkdir -p /usr/src/oauth2_proxy \
    && mkdir -p /go \
    && export GOPATH=/go GOBIN=/usr/local/bin PATH=/go/bin:/usr/local/go/bin:$PATH \
    && cd /usr/src/oauth2_proxy \
    && wget "https://github.com/${OAUTH2_PROXY_REPO}/archive/${OAUTH2_PROXY_COMMIT}.tar.gz" -O oauth2_proxy.tar.gz \
    && tar -C /usr/src/oauth2_proxy -xzf oauth2_proxy.tar.gz --strip-components=1 \
    && go get -v -d \
    && wget -O foo.patch https://github.com/postmates/oauth2_proxy/commit/5a27234e167a81f4bccd668a7171b797289d3db0.patch \
    && wget -O foo2.patch https://github.com/kfox1111/oauth2_proxy/commit/5b8eaaf97c695c0df7df478da8bc9d9ce98061d7.patch \
    && wget -O foo3.patch https://github.com/kfox1111/oauth2_proxy/commit/56a73266dabe58531423de8fc91288f95636924f.patch \
    && patch -p1 < foo.patch \
    && patch -p1 < foo2.patch \
    && patch -p1 < foo3.patch \
    && cd /go/src/github.com/bitly/oauth2_proxy/ \
    && patch -p1 < /usr/src/oauth2_proxy/foo.patch \
    && patch -p1 < /usr/src/oauth2_proxy/foo2.patch \
    && patch -p1 < /usr/src/oauth2_proxy/foo3.patch \
    && cd - \
    && rm -f foo.patch \
    && rm -f foo2.patch \
    && go install -v \
    && rm -rf /go /usr/src/oauth2_proxy /usr/local/go \
    && apk del .build-deps

EXPOSE 4180
ENTRYPOINT [ "/usr/local/bin/oauth2_proxy" ]
CMD [ "-help" ]
