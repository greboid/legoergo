FROM ghcr.io/greboid/dockerfiles/golang as ergo
WORKDIR /app
RUN git clone --no-tags --branch v2.11.0 --single-branch --depth 1 https://github.com/ergochat/ergo .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM ghcr.io/greboid/dockerfiles/golang as certwrapper
WORKDIR /app
RUN git clone --no-tags --branch v4.1.0 --single-branch --depth 1 https://github.com/csmith/certwrapper .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM ghcr.io/greboid/dockerfiles/golang:latest as builder

WORKDIR /app

COPY . /app

RUN mkdir /ircd

FROM ghcr.io/greboid/dockerfiles/base

COPY --from=builder --chown=65532 /ircd /ircd
COPY --from=ergo --chown=65532 /app/languages /ircd-bin/languages
COPY --from=ergo --chown=65532 /app/main /ergo
COPY --from=certwrapper --chown=65532 /app/main /certwrapper

WORKDIR /ircd

VOLUME /ircd

CMD ["/certwrapper", "/ergo", "run", "--conf", "/ircd/ircd.yaml"]
