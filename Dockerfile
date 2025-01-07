FROM --platform=linux/amd64 ubuntu:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    libatomic1 \
    ca-certificates \
    ffmpeg \
    libcap2-bin \
    sqlite3 \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create teaspeak user and group
RUN groupadd -r teaspeak && \
    useradd -r -g teaspeak -m -d /teaspeak teaspeak

WORKDIR /teaspeak

# Download and extract TeaSpeak
RUN wget https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-1.4.22.tar.gz \
    && tar -xzf TeaSpeak-1.4.22.tar.gz \
    && rm TeaSpeak-1.4.22.tar.gz

# Create necessary directories
RUN mkdir -p /teaspeak/logs && \
    mkdir -p /teaspeak/files && \
    mkdir -p /teaspeak/config && \
    mkdir -p /teaspeak/data && \
    mkdir -p /teaspeak/database && \
    mkdir -p /teaspeak/certs

# Generate SSL certificates
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 -keyout /teaspeak/certs/query_key.pem \
    -out /teaspeak/certs/query_cert.pem \
    -subj "/CN=teaspeak/O=teaspeak/C=US" && \
    chmod 644 /teaspeak/certs/query_*.pem

# Set proper permissions
RUN chown -R teaspeak:teaspeak /teaspeak && \
    chmod -R 755 /teaspeak && \
    chmod -R 777 /teaspeak/logs && \
    chmod -R 777 /teaspeak/data && \
    chmod -R 777 /teaspeak/config && \
    chmod -R 777 /teaspeak/database && \
    chmod -R 755 /teaspeak/certs

# Set capabilities
RUN setcap 'cap_net_bind_service=+ep' /teaspeak/TeaSpeakServer

USER teaspeak

# Expose ports
EXPOSE 9987/tcp
EXPOSE 9987/udp
EXPOSE 10101
EXPOSE 30303

# Copy and setup start script
COPY --chown=teaspeak:teaspeak start.sh .
RUN chmod +x start.sh

# Set environment variables
ENV VOICE_PORT=9987 \
    QUERY_PORT=10101 \
    FILE_PORT=30303

CMD ["./start.sh"]