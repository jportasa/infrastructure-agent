FROM ubuntu:16.04

RUN apt-get update -y && apt-get install -y  curl git gcc

## Go install
RUN curl https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar xz \
    && chown -R root:root ./go \
    && mv go /usr/local

# Let's people find our Go binaries
ENV PATH $PATH:/usr/local/go/bin:/go/bin
ENV GOROOT /usr/local/go
ENV GOPATH /go