FROM --platform=linux/amd64 ubuntu:latest

LABEL version="2.0" \
    description="A simple TeaSpeak server running on debian 11" \
    org.opencontainers.image.description="A simple TeaSpeak server running on debian 11"

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Primeira etapa: Instalação básica
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Segunda etapa: Configuração de certificados
RUN mkdir -p /usr/share/ca-certificates/local && \
    update-ca-certificates

# Terceira etapa: Instalação das demais dependências
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget \
    curl \
    ffmpeg \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Quarta etapa: Configuração do TeaSpeak
RUN mkdir -p /ts /ts/logs /ts/certs /ts/files /ts/database /ts/config /ts/crash_dumps && \
    wget -nv -O /ts/TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" && \
    tar -xzf /ts/TeaSpeak.tar.gz -C /ts && \
    rm /ts/TeaSpeak.tar.gz && \
    echo "" > /ts/config/config.yml && \
    ln -sf /ts/config/config.yml /ts/config.yml

# Quinta etapa: Configuração de timezone e usuário
RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    groupadd -g ${gid} teaspeak && \
    useradd -M -u ${uid} -g ${gid} teaspeak && \
    chown -R ${uid}:${gid} /ts && \
    chmod +x /ts/TeaSpeakServer

WORKDIR /ts

EXPOSE 9987/tcp 9987/udp 10101/tcp 30303/tcp

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/ts/libs/" \
    TZ="America/Sao_Paulo"

USER teaspeak

ENTRYPOINT ["./TeaSpeakServer"]
CMD ["-Pgeneral.database.url=sqlite://database/TeaData.sqlite"]