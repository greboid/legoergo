FROM ghcr.io/greboid/dockerfiles/golang@sha256:b39e962ca9b7c2d31ba231c4912fc7831d59dfbb5dcd5e3fa9bba79bd51cc32c as ergo
WORKDIR /app
RUN git clone --no-tags --branch v2.7.0 --single-branch --depth 1 https://github.com/ergochat/ergo .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM ghcr.io/greboid/dockerfiles/golang@sha256:b39e962ca9b7c2d31ba231c4912fc7831d59dfbb5dcd5e3fa9bba79bd51cc32c as certwrapper
WORKDIR /app
RUN git clone --no-tags --branch v4.0.0 --single-branch --depth 1 https://github.com/csmith/certwrapper .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM ghcr.io/greboid/dockerfiles/golang@sha256:b39e962ca9b7c2d31ba231c4912fc7831d59dfbb5dcd5e3fa9bba79bd51cc32c as builder

WORKDIR /app

COPY . /app

RUN mkdir /ircd

FROM ghcr.io/greboid/dockerfiles/base@sha256:82873fbcddc94e3cf77fdfe36765391b6e6049701623a62c2a23248d2a42b1cf

COPY --from=builder --chown=65532 /ircd /ircd
COPY --from=ergo --chown=65532 /app/languages /ircd-bin/languages
COPY --from=ergo --chown=65532 /app/main /ergo
COPY --from=certwrapper --chown=65532 /app/main /certwrapper

WORKDIR /ircd

VOLUME /ircd

CMD ["/certwrapper", "/ergo", "run", "--conf", "/ircd/ircd.yaml"]
