FROM registry.greboid.com/mirror/golang:latest as ergo
WORKDIR /app
RUN git clone --no-tags --branch v2.7.0 --single-branch --depth 1 https://github.com/ergochat/ergo .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM registry.greboid.com/mirror/golang:latest as certwrapper
WORKDIR /app
RUN git clone --no-tags --branch v2.0.0 --single-branch --depth 1 https://github.com/csmith/certwrapper .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -gcflags=./dontoptimizeme=-N -ldflags=-s -o /app/main .

FROM registry.greboid.com/mirror/golang:latest as builder

ENV USER=appuser
ENV UID=10001

WORKDIR /app

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/app" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

COPY . /app

RUN mkdir /ircd

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder --chown=appuser /ircd /ircd
COPY --from=ergo /app/languages /ircd-bin/languages
COPY --from=ergo /app/main /ergo
COPY --from=certwrapper /app/main /certwrapper

WORKDIR /ircd

VOLUME /ircd

CMD ["/certwrapper", "/ergo", "run", "--conf", "/ircd/ircd.yaml"]
