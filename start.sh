#!/bin/bash

# Create required directories
mkdir -p /teaspeak/logs /teaspeak/files /teaspeak/config /teaspeak/data /teaspeak/database

# Set permissions
chmod -R 777 /teaspeak/logs /teaspeak/data /teaspeak/config /teaspeak/database

# Modify existing config.yml
# Change experimental_31 to 1
sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config/config.yml

# Change allow_weblist to 0
sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config/config.yml

# Update ports in the config if needed
sed -i "s/port: 9987/port: ${VOICE_PORT}/g" /teaspeak/config/config.yml
sed -i "s/port: 10101/port: ${QUERY_PORT}/g" /teaspeak/config/config.yml
sed -i "s/port: 30303/port: ${FILE_PORT}/g" /teaspeak/config/config.yml

# Start TeaSpeak server
exec ./TeaSpeakServer