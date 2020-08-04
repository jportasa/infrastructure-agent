FROM golang:1.14-alpine

RUN apk add --no-cache bash \
                       curl \
                       docker-cli \
                       git \
                       rpm \
                       gnupg \
                       jq

RUN curl -sfL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | sh

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "-h" ]


