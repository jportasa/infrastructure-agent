FROM alpine

RUN apk add --no-cache bash \
                       curl \
                       docker-cli \
                       git \
                       rpm \
                       gnupg \
                       jq
# Install Go releases
COPY --from=golang:1.9-alpine /usr/local/go/ /usr/local/go1.9/
COPY --from=golang:1.14-alpine /usr/local/go/ /usr/local/go1.14/
ENV PATH="/usr/local/go1.14/bin:${PATH}"

## Install goreleaser
RUN curl -sfL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | sh

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "-h" ]


