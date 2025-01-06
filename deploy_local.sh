#!/bin/bash

# Exit on any error
set -e

# Configuration
TEASPEAK1_NAME="ts3"

function check_docker_installed {
    if ! command -v docker &> /dev/null; then
        echo "Please install Docker first"
        exit 1
    fi
}

function create_directories {
    # Criar estrutura dentro do volume Railway (/data)
    mkdir -p data/${TEASPEAK1_NAME}/{data,config,logs}
    chmod -R 777 data
}

function run_teaspeak_container {
    local name=$1
    local voice_port=$2
    local query_port=$3
    local file_port=$4
    local exposed_voice_port=$5
    local exposed_query_port=$6
    local exposed_file_port=$7

    docker run -d \
        --name "$name" \
        --restart always \
        -e VOICE_PORT="$voice_port" \
        -e QUERY_PORT="$query_port" \
        -e FILE_PORT="$file_port" \
        -p "$exposed_voice_port:$voice_port/udp" \
        -p "$exposed_query_port:$query_port" \
        -p "$exposed_file_port:$file_port" \
        -v "/data/$name/data:/teaspeak/data" \
        -v "/data/$name/config:/teaspeak/config" \
        -v "/data/$name/logs:/teaspeak/logs" \
        teaspeak

    sleep 5
    docker exec "$name" sh -c "sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config.yml"
    docker exec "$name" sh -c "sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config.yml"
}

# Main execution
check_docker_installed
create_directories

docker build -t teaspeak .

run_teaspeak_container "$TEASPEAK1_NAME" 9987 10101 30303 9987 10101 30303

echo -e "\nTeaSpeak servers running at:"
echo "Server 1: localhost:9987"
