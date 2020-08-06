FROM alpine

RUN apk --update add bash curl jq libarchive-tools;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
