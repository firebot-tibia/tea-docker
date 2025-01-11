FROM --platform=linux/amd64 ubuntu:latest

LABEL version="2.0" \
    description="A simple TeaSpeak server running on debian 11" \
    org.opencontainers.image.description="A simple TeaSpeak server running on debian 11"

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Copiar script de inicialização
COPY start.sh /ts/start.sh

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
        tree \  # Adicionar tree para melhor visualização
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /ts /ts/logs /ts/certs /ts/files /ts/database /ts/config /ts/crash_dumps \
    && cd /ts \
    && wget -nv -O TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" \
    && echo "=== Conteúdo do arquivo tar ===" \
    && tar -tvf TeaSpeak.tar.gz \
    && echo "=== Extraindo arquivo ===" \
    && tar -xzvf TeaSpeak.tar.gz \
    && echo "=== Conteúdo do diretório após extração ===" \
    && ls -la /ts \
    && tree /ts \
    && echo "=== Procurando executável ===" \
    && find /ts -type f -executable \
    && rm TeaSpeak.tar.gz \
    && echo "" > /ts/config/config.yml \
    && ln -sf /ts/config/config.yml /ts/config.yml


RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    groupadd -g ${gid} teaspeak && \
    useradd -M -u ${uid} -g ${gid} teaspeak && \
    chmod +x /ts/TeaSpeakServer && \
    chmod +x /ts/start.sh && \
    chown -R ${uid}:${gid} /ts

WORKDIR /ts

# Portas necessárias para o TeaSpeak
EXPOSE 9987/tcp  
EXPOSE 9987/udp  
EXPOSE 10101/tcp 
EXPOSE 30303/tcp 

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/ts/libs/" \
    TZ="America/Sao_Paulo"

USER teaspeak

ENTRYPOINT ["/bin/bash", "-c", "\
    echo '=== Current Directory ==='; \
    pwd; \
    echo '=== Directory Content ==='; \
    ls -la; \
    echo '=== Executables ==='; \
    find . -type f -executable; \
    echo '=== Starting TeaSpeak ==='; \
    exec ./TeaSpeakServer -Pgeneral.database.url=sqlite://database/TeaData.sqlite \
"]