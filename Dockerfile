FROM --platform=linux/amd64 debian:stable-slim

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Update package lists and upgrade
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils

# Install essential packages first
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    openssl \
    wget \
    curl \
    && apt-get clean

# Install multimedia packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
    ffmpeg \
    && apt-get clean

# Install Python and other dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
    tzdata \
    cron \
    sudo \
    python3 \
    python3-pip \
    && apt-get clean

# Install libjemalloc separately and handle its setup
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
    libjemalloc2 \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /teaspeak/libs && \
    find /usr/lib -name "libjemalloc.so*" -exec ln -sf {} /teaspeak/libs/libjemalloc.so.2 \; || true

# Install yt-dlp using curl
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp && \
    ln -s /usr/local/bin/yt-dlp /usr/local/bin/youtube-dl

WORKDIR /teaspeak

# Create all required directories
RUN mkdir -p /teaspeak/logs \
    /teaspeak/files \
    /teaspeak/config \
    /teaspeak/data \
    /teaspeak/database \
    /teaspeak/certs \
    /teaspeak/scripts \
    /teaspeak/database/backups

# Copy scripts and set permissions
COPY scripts/ /teaspeak/scripts/
RUN chmod +x /teaspeak/scripts/*.sh && \
    echo "# Run backup twice per week (Wednesday and Sunday at 3 AM)" > /etc/cron.d/teaspeak-backup && \
    echo "0 3 * * 0,3 /teaspeak/scripts/automated-backup.sh >> /teaspeak/database/backups/cron.log 2>&1" >> /etc/cron.d/teaspeak-backup && \
    echo "" >> /etc/cron.d/teaspeak-backup && \
    chmod 0644 /etc/cron.d/teaspeak-backup

# Download and install TeaSpeak
RUN wget -nv -O /teaspeak/TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" && \
    tar -xzf /teaspeak/TeaSpeak.tar.gz -C /teaspeak && \
    rm /teaspeak/TeaSpeak.tar.gz && \
    echo "" > /teaspeak/config/config.yml && \
    ln -sf /teaspeak/config/config.yml /teaspeak/config.yml

# Create ffmpeg symbolic links
RUN ln -sf /usr/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /usr/bin/ffprobe /usr/local/bin/ffprobe

RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    groupadd -g ${gid} teaspeak && \
    useradd -M -u ${uid} -g ${gid} teaspeak && \
    chmod +x /teaspeak/TeaSpeakServer && \
    chown -R ${uid}:${gid} /teaspeak

# Configure sudo for teaspeak user and cron permissions
RUN echo "teaspeak ALL=(ALL) NOPASSWD: /usr/sbin/service cron start" >> /etc/sudoers && \
    echo "teaspeak ALL=(ALL) NOPASSWD: /usr/bin/crontab" >> /etc/sudoers && \
    echo "teaspeak ALL=(ALL) NOPASSWD: /usr/sbin/cron" >> /etc/sudoers

# Set up entrypoint with proper permissions
RUN echo '#!/bin/bash' > /teaspeak/scripts/entrypoint.sh && \
    echo 'sudo service cron start || true' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'sudo crontab -u teaspeak /etc/cron.d/teaspeak-backup || true' >> /teaspeak/scripts/entrypoint.sh && \
    echo '/teaspeak/scripts/generate-cert.sh' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'exec ./TeaSpeakServer "$@"' >> /teaspeak/scripts/entrypoint.sh && \
    chmod +x /teaspeak/scripts/entrypoint.sh

# Add certificate generation script
COPY scripts/generate-cert.sh /teaspeak/scripts/
RUN chmod +x /teaspeak/scripts/generate-cert.sh

EXPOSE 9987/tcp  
EXPOSE 9987/udp  
EXPOSE 10101/tcp 
EXPOSE 30303/tcp 

ENV LD_LIBRARY_PATH="/teaspeak/libs:/usr/lib/x86_64-linux-gnu:/usr/lib:${LD_LIBRARY_PATH}" \
    LD_PRELOAD="/teaspeak/libs/libjemalloc.so.2" \
    SERVER_VERSION="${SERVER_VERSION:-latest-$(date +%d%m%y)}" \
    TZ="America/Sao_Paulo" \
    PATH="/usr/local/bin:${PATH}"

USER teaspeak

ENTRYPOINT ["/teaspeak/scripts/entrypoint.sh"]
CMD ["-Pgeneral.database.url=sqlite://database/TeaData.sqlite"]