FROM alpine:3.12

RUN apk --update add bash curl jq zip libarchive-tools;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
