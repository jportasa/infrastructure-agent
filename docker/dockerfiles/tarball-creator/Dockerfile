FROM alpine

RUN apk --update add bash wget curl jq;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
