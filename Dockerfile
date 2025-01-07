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
    && rm -rf /var/lib/apt/lists/*

# Create teaspeak user and group
RUN groupadd -r teaspeak && \
    useradd -r -g teaspeak -m -d /teaspeak teaspeak

WORKDIR /teaspeak

# Download and extract TeaSpeak
RUN wget https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-1.4.22.tar.gz \
    && tar -xzf TeaSpeak-1.4.22.tar.gz \
    && rm TeaSpeak-1.4.22.tar.gz

# Create necessary directories and set permissions
RUN mkdir -p /teaspeak/logs && \
    mkdir -p /teaspeak/files && \
    mkdir -p /teaspeak/config && \
    mkdir -p /teaspeak/data && \
    mkdir -p /teaspeak/database && \
    chown -R teaspeak:teaspeak /teaspeak && \
    chmod -R 755 /teaspeak && \
    chmod 777 /teaspeak/logs && \
    chmod 777 /teaspeak/data && \
    chmod 777 /teaspeak/config && \
    chmod 777 /teaspeak/database

# Set capabilities for binding to privileged ports
RUN setcap 'cap_net_bind_service=+ep' /teaspeak/TeaSpeakServer

USER teaspeak

# Expose required ports
EXPOSE 9987/tcp
EXPOSE 9987/udp
EXPOSE 10101
EXPOSE 30303

# Copy start script
COPY --chown=teaspeak:teaspeak start.sh .
RUN chmod +x start.sh

# Set environment variables
ENV VOICE_PORT=9987 \
    QUERY_PORT=10101 \
    FILE_PORT=30303

CMD ["./start.sh"]