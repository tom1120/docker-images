FROM nginx:1.17.6-alpine
ENV LANG=C.UTF-8

RUN apk add --no-cache \
        vim \
        git \
        bash \
        rsync \
        openssl \
        sshpass \
        python3 \
        openssh-client \
        ca-certificates \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        libffi-dev \
        openssl-dev \
        python3-dev \
    && pip3 install --no-cache-dir --upgrade pip cffi -i https://mirrors.aliyun.com/pypi/simple/ \
    && pip3 install --no-cache-dir --upgrade pycrypto pywinrm -i https://mirrors.aliyun.com/pypi/simple/ \
    && pip3 install --no-cache-dir ansible==2.8.5 netaddr==0.7.19 -i https://mirrors.aliyun.com/pypi/simple/ \
    && apk del .build-deps
