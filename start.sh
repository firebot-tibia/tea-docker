#!/bin/bash

if [ "$DEPLOY" = "true" ]; then
    chmod +x ./deploy.sh
    ./deploy.sh
fi

# Ensure TeaSpeak server is executable
chmod +x ./TeaSpeakServer

# Start TeaSpeak server
exec ./TeaSpeakServer