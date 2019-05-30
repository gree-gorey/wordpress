FROM alpine:3.8

# Just install bash, kubectl, helm
RUN apk add --update bash && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.13.1/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/bin/ && \
    wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz && \
    tar -zxvf helm-v2.9.1-linux-amd64.tar.gz && \
    chmod +x ./linux-amd64/helm && \
    mv ./linux-amd64/helm /usr/bin/ && \
    rm -rf ./helm* && rm -rf /var/cache/apk/*
