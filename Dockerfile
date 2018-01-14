# A preinstalled pelican with image optimizer installed
FROM alpine:3.7

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/apihackers/docker-pelican" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0"

# Add Edge and bleeding repos
RUN echo -e '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo -e '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

# Install common dependencies
RUN apk --update --no-cache add \
    bash \
    curl \
    gettext \
    gifsicle \
    imagemagick \
    libffi \
    libjpeg \
    libpng \
    libxml2 \
    libxslt \
    pngquant \
    python3 \
    yaml \
    zlib \
    && python3 -m ensurepip --upgrade \
    && rm -r /usr/lib/python*/ensurepip

# Version change should trigger a rebuild
ENV MOZJPEG_VERSION 3.2

# # Install build dependencies as virtual, build MozJpeg and remove them
RUN apk --update --no-cache add --virtual build-dependencies \
    # Common build tools
    autoconf automake build-base libtool nasm \
    # Install MozJPEG from sources
    && curl -L -O https://github.com/mozilla/mozjpeg/releases/download/v$MOZJPEG_VERSION/mozjpeg-$MOZJPEG_VERSION-release-source.tar.gz \
    && tar zxf mozjpeg-$MOZJPEG_VERSION-release-source.tar.gz \
    && cd mozjpeg \
    && autoreconf -fiv \
    && ./configure --prefix=/usr && make && make install \
    && cd .. \
    && rm -fr mozjpeg \
    # Uninstall build dependencies
    && apk del build-dependencies

COPY requirements.pip /tmp/requirements.pip

# Install commonly used requirements
RUN apk --no-cache add --virtual build-dependencies \
        python3-dev yaml-dev build-base libffi-dev libxml2-dev libxslt-dev\
    && pip3 install -r /tmp/requirements.pip \
    && apk del build-dependencies \
    && rm -r /root/.cache
