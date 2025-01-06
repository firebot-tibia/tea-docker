#!/bin/bash

# Exit on any error
set -e

# Configuration
TEASPEAK_NAME="ts3"

# Basic functions
function check_docker_installed {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found, installing Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        check_docker_permissions
    fi
}

function check_docker_permissions {
    if ! groups | grep -q "docker"; then
        sudo usermod -aG docker $USER
        echo "Added to docker group. Please logout and login again."
        exit 1
    fi
}

function create_directories {
    mkdir -p data/${TEASPEAK_NAME}/{data,config,logs}
    chmod -R 777 data
}

function run_teaspeak_container {
    local name=$1
    local voice_port=$2
    local query_port=$3
    local file_port=$4

    docker run -d \
        --name "$name" \
        --restart always \
        -e VOICE_PORT="$voice_port" \
        -e QUERY_PORT="$query_port" \
        -e FILE_PORT="$file_port" \
        --cap-add=NET_BIND_SERVICE \
        -p "$voice_port:$voice_port/udp" \
        -p "$query_port:$query_port" \
        -p "$file_port:$file_port" \
        -v "/data/$name/data:/teaspeak/data" \
        -v "/data/$name/config:/teaspeak/config" \
        -v "/data/$name/logs:/teaspeak/logs" \
        teaspeak

    sleep 5
    docker exec "$name" sh -c "sed -i 's/experimental_31: 0/experimental_31: 1/g' /teaspeak/config.yml"
    docker exec "$name" sh -c "sed -i 's/allow_weblist: 1/allow_weblist: 0/g' /teaspeak/config.yml"
}

function configure_firewall {
    sudo ufw allow 9987/udp
    sudo ufw allow 10101/tcp
    sudo ufw allow 30303/tcp
    sudo ufw --force enable
    sudo ufw reload
}

# Main execution
check_docker_installed
check_docker_permissions
create_directories
configure_firewall

docker build -t teaspeak .

run_teaspeak_container "$TEASPEAK_NAME" 9987 10101 30303

EXTERNAL_IP=$(curl -s ifconfig.me)
echo -e "\nTeaSpeak server running at:"
echo "Server: $EXTERNAL_IP:9987"