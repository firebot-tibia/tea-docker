FROM --platform=linux/amd64 ubuntu:latest

LABEL version="2.0" \
    description="A simple TeaSpeak server running on debian 11" \
    org.opencontainers.image.description="A simple TeaSpeak server running on debian 11"

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Combine RUN commands and add error handling
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        curl \
        ffmpeg \
        tzdata \
    && mkdir -p /usr/share/ca-certificates/local \
    && update-ca-certificates \
    # Create directories
    && mkdir -p /ts /ts/logs /ts/certs /ts/files /ts/database /ts/config /ts/crash_dumps \
    # Download specific TeaSpeak version
    && wget -nv -O /ts/TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" \
    && tar -xzf /ts/TeaSpeak.tar.gz -C /ts \
    && rm /ts/TeaSpeak.tar.gz \
    && echo "" > /ts/config/config.yml \
    && ln -sf /ts/config/config.yml /ts/config.yml \
    # Setup timezone
    && ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    # Setup user and permissions
    && groupadd -g ${gid} teaspeak \
    && useradd -M -u ${uid} -g ${gid} teaspeak \
    && chown -R ${uid}:${gid} /ts \
    # Cleanup
    && apt-get remove -y wget curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ts

EXPOSE 9987/tcp 9987/udp 10101/tcp 30303/tcp

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/ts/libs/" \
    TZ="America/Sao_Paulo"

USER teaspeak

ENTRYPOINT ["./TeaSpeakServer"]
CMD ["-Pgeneral.database.url=sqlite://database/TeaData.sqlite"]