FROM --platform=linux/amd64 ubuntu:latest

RUN apt-get update && apt-get install -y \
    wget tar libatomic1 ca-certificates ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -U -m -d /teaspeak teaspeak

WORKDIR /teaspeak

RUN wget https://repo.teaspeak.de/server/linux/amd64/TeaSpeak-1.5.6.tar.gz \
    && tar -xzf TeaSpeak-1.5.6.tar.gz \
    && rm TeaSpeak-1.5.6.tar.gz \
    && chown -R teaspeak:teaspeak /teaspeak

USER teaspeak

EXPOSE 9987/udp 10101 30303

COPY --chown=teaspeak:teaspeak start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]