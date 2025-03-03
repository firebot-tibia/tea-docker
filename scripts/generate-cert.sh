#!/bin/bash
# Check if certificate already exists
if [ ! -f /teaspeak/certs/cert.pem ] || [ ! -f /teaspeak/certs/key.pem ]; then
    echo "Generating self-signed certificate for TeaSpeak server..."
    
    # Generate private key and certificate
    openssl req -x509 -newkey rsa:4096 -keyout /teaspeak/certs/key.pem -out /teaspeak/certs/cert.pem -days 365 -nodes -subj "/CN=teaspeak-server" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:192.168.90.2,IP:192.168.90.3,IP:192.168.0.113"
    
    # Set proper permissions
    chmod 600 /teaspeak/certs/key.pem
    chmod 644 /teaspeak/certs/cert.pem
    
    echo "Certificate generated successfully!"
else
    echo "Certificate already exists. Skipping generation."
fi