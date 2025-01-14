FROM --platform=linux/amd64 ubuntu:latest

LABEL version="2.0" \
    maintainer="ESh4d0w, Markus Hadenfeldt <docker@teaspeak.de>, h1dden-da3m0n" \
    description="A simple TeaSpeak server running on ubuntu 18.04 (amd64_stable)"

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Primeira etapa: Instalação básica
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    openssl \
    wget \
    curl \
    ffmpeg \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /teaspeak

# Create necessary directories
RUN mkdir -p /teaspeak/logs && \
    mkdir -p /teaspeak/files && \
    mkdir -p /teaspeak/config && \
    mkdir -p /teaspeak/data && \
    mkdir -p /teaspeak/database && \
    mkdir -p /teaspeak/certs

# Segunda etapa: Configuração do TeaSpeak
RUN wget -nv -O /teaspeak/TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" && \
    tar -xzf /teaspeak/TeaSpeak.tar.gz -C /teaspeak && \
    rm /teaspeak/TeaSpeak.tar.gz && \
    echo "" > /teaspeak/config/config.yml && \
    ln -sf /teaspeak/config/config.yml /teaspeak/config.yml


# Terceira etapa: Configuração de timezone, usuário e permissões
RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    groupadd -g ${gid} teaspeak && \
    useradd -M -u ${uid} -g ${gid} teaspeak && \
    chmod +x /teaspeak/TeaSpeakServer && \
    chown -R ${uid}:${gid} /teaspeak

# Portas necessárias para o TeaSpeak
EXPOSE 9987/tcp  
EXPOSE 9987/udp  
EXPOSE 10101/tcp 
EXPOSE 30303/tcp 

VOLUME ["/ts/logs", "/ts/certs", "/ts/config", "/ts/files", "/ts/database", "/ts/crash_dumps"]

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/ts/libs/" \
    LD_PRELOAD="/ts/libs/libjemalloc.so.2" \
    SERVER_VERSION="${SERVER_VERSION:-latest-$(date +%d%m%y)}" \
    TZ="Europe/Berlin"


USER teaspeak

ENTRYPOINT ["./TeaSpeakServer"]

CMD ["-Pgeneral.database.url=sqlite://database/TeaData.sqlite"]