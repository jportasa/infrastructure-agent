FROM alpine

RUN apk --update add make curl docker

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
