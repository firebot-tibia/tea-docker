FROM --platform=linux/amd64 debian:stable-slim

ARG TARGETPLATFORM
ARG uid=4242
ARG gid=4242
ARG TEASPEAK_VERSION=1.4.22

# Update package lists and upgrade
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils

# Install essential packages with enhanced certificate handling
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    openssl \
    wget \
    curl \
    && apt-get clean \
    # Update CA certificates
    && update-ca-certificates --fresh \
    # Create directory for custom certificates
    && mkdir -p /usr/local/share/ca-certificates/custom

# Create certificate helper script
RUN echo '#!/bin/bash' > /usr/local/bin/add-cert && \
    echo 'if [ "$#" -ne 2 ]; then' >> /usr/local/bin/add-cert && \
    echo '  echo "Usage: add-cert <certificate-file> <cert-name>"' >> /usr/local/bin/add-cert && \
    echo '  exit 1' >> /usr/local/bin/add-cert && \
    echo 'fi' >> /usr/local/bin/add-cert && \
    echo 'CERT_FILE=$1' >> /usr/local/bin/add-cert && \
    echo 'CERT_NAME=$2' >> /usr/local/bin/add-cert && \
    echo 'cp "$CERT_FILE" "/usr/local/share/ca-certificates/custom/$CERT_NAME.crt"' >> /usr/local/bin/add-cert && \
    echo 'update-ca-certificates' >> /usr/local/bin/add-cert && \
    echo 'echo "Certificate added successfully"' >> /usr/local/bin/add-cert && \
    chmod +x /usr/local/bin/add-cert

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

# Configure Python to use system certificates
RUN pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Install yt-dlp using curl with certificate verification
RUN curl -L --cacert /etc/ssl/certs/ca-certificates.crt \
    https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
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
RUN wget --ca-certificate=/etc/ssl/certs/ca-certificates.crt -nv -O /teaspeak/TeaSpeak.tar.gz \
        "https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz" && \
    tar -xzf /teaspeak/TeaSpeak.tar.gz -C /teaspeak && \
    rm /teaspeak/TeaSpeak.tar.gz && \
    echo "" > /teaspeak/config/config.yml && \
    ln -sf /teaspeak/config/config.yml /teaspeak/config.yml

# Copy protocol key file
COPY data/license/protocol_key.txt /teaspeak/protocol_key.txt

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
    echo "teaspeak ALL=(ALL) NOPASSWD: /usr/sbin/cron" >> /etc/sudoers && \
    echo "teaspeak ALL=(ALL) NOPASSWD: /usr/local/bin/add-cert" >> /etc/sudoers

# Create certificate verification helper script
RUN echo '#!/bin/bash' > /teaspeak/scripts/check-certs.sh && \
    echo 'echo "Checking certificate validity for teaspeak.de..."' >> /teaspeak/scripts/check-certs.sh && \
    echo 'echo | openssl s_client -connect repo.teaspeak.de:443 -servername repo.teaspeak.de' >> /teaspeak/scripts/check-certs.sh && \
    echo 'echo "Certificate verification complete"' >> /teaspeak/scripts/check-certs.sh && \
    chmod +x /teaspeak/scripts/check-certs.sh

# Create certificate generator for self-signed certs
RUN echo '#!/bin/bash' > /teaspeak/scripts/generate-cert.sh && \
    echo 'if [ ! -f "/teaspeak/certs/certificate.pem" ] || [ ! -f "/teaspeak/certs/private_key.pem" ]; then' >> /teaspeak/scripts/generate-cert.sh && \
    echo '  echo "Generating self-signed certificate for TeaSpeak..."' >> /teaspeak/scripts/generate-cert.sh && \
    echo '  IP=$(hostname -I | awk "{print \$1}")' >> /teaspeak/scripts/generate-cert.sh && \
    echo '  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\' >> /teaspeak/scripts/generate-cert.sh && \
    echo '    -keyout /teaspeak/certs/private_key.pem \\' >> /teaspeak/scripts/generate-cert.sh && \
    echo '    -out /teaspeak/certs/certificate.pem \\' >> /teaspeak/scripts/generate-cert.sh && \
    echo '    -subj "/CN=teaspeak.server/O=TeaSpeak/C=BR" \\' >> /teaspeak/scripts/generate-cert.sh && \
    echo '    -addext "subjectAltName = DNS:teaspeak.server,DNS:localhost,IP:127.0.0.1,IP:${IP}"' >> /teaspeak/scripts/generate-cert.sh && \
    echo 'else' >> /teaspeak/scripts/generate-cert.sh && \
    echo '  echo "Certificate already exists, skipping generation"' >> /teaspeak/scripts/generate-cert.sh && \
    echo 'fi' >> /teaspeak/scripts/generate-cert.sh && \
    chmod +x /teaspeak/scripts/generate-cert.sh

# Set up entrypoint with proper permissions
RUN echo '#!/bin/bash' > /teaspeak/scripts/entrypoint.sh && \
    echo 'sudo service cron start || true' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'sudo crontab -u teaspeak /etc/cron.d/teaspeak-backup || true' >> /teaspeak/scripts/entrypoint.sh && \
    echo '# Run certificate generator' >> /teaspeak/scripts/entrypoint.sh && \
    echo '/teaspeak/scripts/generate-cert.sh' >> /teaspeak/scripts/entrypoint.sh && \
    echo '# Check if we need to add any custom certificates from environment' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'if [ -n "$CUSTOM_CA_CERT" ] && [ -f "$CUSTOM_CA_CERT" ]; then' >> /teaspeak/scripts/entrypoint.sh && \
    echo '  echo "Adding custom CA certificate from $CUSTOM_CA_CERT"' >> /teaspeak/scripts/entrypoint.sh && \
    echo '  sudo add-cert "$CUSTOM_CA_CERT" "custom-ca"' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'fi' >> /teaspeak/scripts/entrypoint.sh && \
    echo 'exec ./TeaSpeakServer "$@"' >> /teaspeak/scripts/entrypoint.sh && \
    chmod +x /teaspeak/scripts/entrypoint.sh

EXPOSE 9987/tcp  
EXPOSE 9987/udp  
EXPOSE 10101/tcp 
EXPOSE 30303/tcp 

ENV LD_LIBRARY_PATH="/teaspeak/libs:/usr/lib/x86_64-linux-gnu:/usr/lib:${LD_LIBRARY_PATH}" \
    LD_PRELOAD="/teaspeak/libs/libjemalloc.so.2" \
    SERVER_VERSION="${SERVER_VERSION:-latest-$(date +%d%m%y)}" \
    TZ="America/Sao_Paulo" \
    PATH="/usr/local/bin:${PATH}" \
    # Certificate verification environment settings
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt" \
    NODE_EXTRA_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

USER teaspeak

ENTRYPOINT ["/teaspeak/scripts/entrypoint.sh"]
CMD ["-Pgeneral.database.url=sqlite://database/TeaData.sqlite"]