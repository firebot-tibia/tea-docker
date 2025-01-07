#!/bin/bash

# Create required directories
mkdir -p /teaspeak/data
mkdir -p /teaspeak/config
mkdir -p /teaspeak/logs

# Set proper permissions
chmod -R 777 /teaspeak/data
chmod -R 777 /teaspeak/config
chmod -R 777 /teaspeak/logs

# Ensure TeaSpeak server is executable
chmod +x ./TeaSpeakServer

# Configure settings before starting
if [ -f /teaspeak/config.yml ]; then
    # Update experimental and weblist settings
    sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config.yml
    sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config.yml
    
    # Configure voice port for both TCP and UDP
    sed -i '/voice:/!b;n;c\  bind: ["0.0.0.0:'"${VOICE_PORT}"'/tcp", "0.0.0.0:'"${VOICE_PORT}"'/udp"]' /teaspeak/config.yml
    sed -i '/voice:/!b;n;n;c\  ip: "0.0.0.0"' /teaspeak/config.yml
    
    echo "Config updated successfully"
else
    echo "Waiting for config file to be created..."
    # Start server temporarily to generate config
    ./TeaSpeakServer &
    PID=$!
    
    # Wait for config file
    for i in {1..30}; do
        if [ -f /teaspeak/config.yml ]; then
            kill $PID
            wait $PID
            
            # Update experimental and weblist settings
            sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config.yml
            sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config.yml
            
            # Configure voice port for both TCP and UDP
            sed -i '/voice:/!b;n;c\  bind: ["0.0.0.0:'"${VOICE_PORT}"'/tcp", "0.0.0.0:'"${VOICE_PORT}"'/udp"]' /teaspeak/config.yml
            sed -i '/voice:/!b;n;n;c\  ip: "0.0.0.0"' /teaspeak/config.yml
            
            echo "Config updated successfully"
            break
        fi
        sleep 1
    done
fi

# Start TeaSpeak server
echo "Starting TeaSpeak server..."
exec ./TeaSpeakServer