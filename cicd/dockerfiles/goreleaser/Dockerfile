FROM alpine:3.12

ARG GORELEASER_VERSION='v0.143.0'

RUN apk add --no-cache bash \
                       curl \
                       docker-cli \
                       git \
                       rpm \
                       gnupg \
                       jq

# To upload assets to GH
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing hub

# Install Go releases
COPY --from=golang:1.9-alpine /usr/local/go/ /usr/local/go1.9/
COPY --from=golang:1.15-alpine /usr/local/go/ /usr/local/go1.15/
ENV PATH="/usr/local/go1.15/bin:${PATH}"

## Install Goreleaser
RUN curl -SL https://github.com/goreleaser/goreleaser/releases/download/$GORELEASER_VERSION/goreleaser_Linux_x86_64.tar.gz | tar xz -C /usr/bin

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "-h" ]


