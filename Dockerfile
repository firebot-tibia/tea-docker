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