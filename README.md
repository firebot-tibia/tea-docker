# TeaSpeak Docker Deployment

This repository contains Docker configuration and deployment scripts for running multiple TeaSpeak servers simultaneously.

## Prerequisites

- Linux-based operating system
- Basic knowledge of Docker and shell commands

## Quick Start

1. Clone the repository:
```bash
cd tea-docker
chmod +x deploy_teaspeak.sh
./deploy_teaspeak.sh
```

```bash
docker build -t teaspeak .
```

```bash
docker run -d \
    --name teaspeak1 \
    --restart always \
    -e VOICE_PORT=9987 \
    -e QUERY_PORT=10101 \
    -e FILE_PORT=30303 \
    -p 9987:9987/udp \
    -p 10101:10101 \
    -p 30303:30303 \
    -v ./persistence/teaspeak1/data:/teaspeak/data \
    -v ./persistence/teaspeak1/config:/teaspeak/config \
    -v ./persistence/teaspeak1/logs:/teaspeak/logs \
    ts3
```


```bash
docker run -d \
    --name teaspeak2 \
    --restart always \
    -e VOICE_PORT=9987 \
    -e QUERY_PORT=10101 \
    -e FILE_PORT=30303 \
    -p 9988:9987/udp \
    -p 10102:10101 \
    -p 30304:30303 \
    -v ./persistence/teaspeak2/data:/teaspeak/data \
    -v ./persistence/teaspeak2/config:/teaspeak/config \
    -v ./persistence/teaspeak2/logs:/teaspeak/logs \
    ourobra
```