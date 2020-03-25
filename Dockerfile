FROM synadia/jsm:latest AS jsm
FROM golang:1.14-alpine3.11 AS builder

LABEL maintainer "Derek Collison <derek@nats.io>"
LABEL maintainer "Waldemar Quevedo <wally@nats.io>"

WORKDIR $GOPATH/src/github.com/nats-io/

RUN apk add -U --no-cache git binutils

RUN go get github.com/nats-io/nats-top

RUN go get -u -ldflags "-X main.version=0.3.16-nats-box" github.com/nats-io/nsc
RUN go get github.com/nats-io/stan.go/examples/stan-pub
RUN go get github.com/nats-io/stan.go/examples/stan-sub
RUN go get github.com/ThreeDotsLabs/watermill-nats/pkg/nats

# Simple tools
COPY ./nats-box ./nats-box
COPY ./nats-gob ./nats-gob
RUN go install ./nats-box
RUN go install ./nats-gob
RUN strip /go/bin/*

FROM alpine:3.11

RUN apk add -U --no-cache ca-certificates figlet

COPY --from=builder /go/bin/* /usr/local/bin/
COPY --from=jsm /usr/local/bin/nats /usr/local/bin/

RUN cd /usr/local/bin/ && ln -s nats-box nats-pub && ln -s nats-box nats-sub && ln -s nats-box nats-req && ln -s nats-box nats-rply && ln -s nats-gob gob-pub

WORKDIR /root

USER root

ENV NKEYS_PATH /nsc/nkeys
ENV NSC_HOME /nsc/accounts
ENV NATS_CONFIG_HOME /nsc/config

COPY .profile $WORKDIR

RUN apk update && apk add gettext

ENTRYPOINT ["/bin/sh", "-l"]
