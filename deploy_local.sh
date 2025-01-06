#!/bin/bash

# Exit on any error
set -e

# Configuration
TEASPEAK1_NAME="ts3"
BASE_DIR="$HOME/teaspeak_data"  # Changed to use home directory

function check_docker_installed {
    if ! command -v docker &> /dev/null; then
        echo "Please install Docker first"
        exit 1
    fi
}

function create_directories {
    # Create directory structure in home directory
    mkdir -p ${BASE_DIR}/${TEASPEAK1_NAME}/{data,config,logs}
    chmod -R 755 ${BASE_DIR}  # More secure permissions
}

function run_teaspeak_container {
    local name=$1
    local voice_port=$2
    local query_port=$3
    local file_port=$4
    local exposed_voice_port=$5
    local exposed_query_port=$6
    local exposed_file_port=$7

    # Run container with platform specification
    docker run --platform linux/amd64 -d \
        --name "$name" \
        --restart always \
        -e VOICE_PORT="$voice_port" \
        -e QUERY_PORT="$query_port" \
        -e FILE_PORT="$file_port" \
        -p "$exposed_voice_port:$voice_port/udp" \
        -p "$exposed_query_port:$query_port" \
        -p "$exposed_file_port:$file_port" \
        -v "${BASE_DIR}/$name/data:/teaspeak/data" \
        -v "${BASE_DIR}/$name/config:/teaspeak/config" \
        -v "${BASE_DIR}/$name/logs:/teaspeak/logs" \
        teaspeak

    # Wait for container to start and config file to be created
    echo "Waiting for container to initialize..."
    sleep 10

    # Modify configuration
    docker exec "$name" sh -c '[ -f /teaspeak/config.yml ] && sed -i "s/experimental_31: 0/experimental_31: 1/g" /teaspeak/config.yml || echo "Config file not found"'
    docker exec "$name" sh -c '[ -f /teaspeak/config.yml ] && sed -i "s/allow_weblist: 1/allow_weblist: 0/g" /teaspeak/config.yml || echo "Config file not found"'
}

function cleanup_existing {
    # Clean up any existing container
    if docker ps -a | grep -q "$TEASPEAK1_NAME"; then
        echo "Removing existing TeaSpeak container..."
        docker rm -f "$TEASPEAK1_NAME"
    fi
}

# Main execution
echo "Checking Docker installation..."
check_docker_installed

echo "Creating directories..."
create_directories

echo "Building Docker image..."
docker build -t teaspeak .

echo "Cleaning up any existing containers..."
cleanup_existing

echo "Starting TeaSpeak server..."
run_teaspeak_container "$TEASPEAK1_NAME" 9987 10101 30303 9987 10101 30303

echo -e "\nTeaSpeak server is running!"
echo "Voice Server: localhost:9987"
echo "Query Port: localhost:10101"
echo "File Transfer: localhost:30303"
echo "Data directory: ${BASE_DIR}/${TEASPEAK1_NAME}"