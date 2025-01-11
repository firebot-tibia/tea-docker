FROM --platform=linux/amd64 ubuntu:latest

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Copiar script de inicialização
COPY start.sh /teaspeak/start.sh

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
    chmod +x /teaspeak/start.sh && \
    chown -R ${uid}:${gid} /teaspeak

# Portas necessárias para o TeaSpeak
EXPOSE 9987/tcp  
EXPOSE 9987/udp  
EXPOSE 10101/tcp 
EXPOSE 30303/tcp 

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/ts/libs/" \
    TZ="America/Sao_Paulo"

USER teaspeak

ENTRYPOINT ["/bin/bash", "-c", "exec ./TeaSpeakServer -Pgeneral.database.url=sqlite://database/TeaData.sqlite"]