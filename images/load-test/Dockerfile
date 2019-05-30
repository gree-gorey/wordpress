FROM alpine:3.8

# Just install curl
RUN apk add --update curl && \
    rm -rf /var/cache/apk/*

ADD ./load.sh /load.sh

CMD ["/bin/sh", "/load.sh"]
