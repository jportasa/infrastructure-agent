FROM alpine

RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash wget jq;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
 git checkout tags/v1.86; \
 cd s3fs-fuse; \
 ./autogen.sh; \
 ./configure --prefix=/usr; \
 make; \
 make install; \
 rm -rf /var/cache/apk/*;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
