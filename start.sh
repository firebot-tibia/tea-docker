#!/bin/bash

# Checar se DEPLOY é true
if [ "$DEPLOY" = "true" ]; then
    echo "Running deployment script..."
    # Create required directories
    mkdir -p /data/ts3/{data,config,logs}
    chmod -R 777 /data

    # Modify config after mounting
    if [ -f /teaspeak/config.yml ]; then
        sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config.yml
        sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config.yml
        echo "Config updated successfully"
    else
        echo "Config file not found"
    fi
fi

# Start TeaSpeak server
exec ./TeaSpeakServer