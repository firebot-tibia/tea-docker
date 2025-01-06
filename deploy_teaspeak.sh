#!/bin/bash

# Exit on any error
set -e

# Configuration
TEASPEAK1_NAME="ts3"
TEASPEAK2_NAME="ourobra"

# Function to check if Docker is installed
function check_docker_installed {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found, installing Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        check_docker_permissions
        echo "Docker installed successfully."
    else
        echo "Docker is already installed."
    fi
}

# Function to check if user has Docker permissions
function check_docker_permissions {
    if ! groups | grep -q "docker"; then
        echo "Adding user to docker group..."
        sudo usermod -aG docker $USER
        echo "Please log out and log back in, or run 'newgrp docker' for changes to take effect."
        echo "Then run this script again."
        exit 1
    fi
}

# Function to create required directories
function create_directories {
    echo "Creating persistence directories..."
    mkdir -p ./persistence/${TEASPEAK1_NAME}/{data,config,logs}
    mkdir -p ./persistence/${TEASPEAK2_NAME}/{data,config,logs}
    chmod -R 777 ./persistence
}

# Function to check if container exists and remove it
function remove_existing_container {
    local container_name=$1
    if docker ps -a | grep -q "$container_name"; then
        echo "Removing existing container: $container_name"
        docker rm -f "$container_name"
    fi
}

# Function to build the Docker image
function build_image {
    echo "Building Docker image..."
    if ! docker build -t teaspeak .; then
        echo "Error: Docker build failed"
        exit 1
    fi
}

# Function to run a teaspeak container
function run_teaspeak_container {
    local name=$1
    local voice_port=$2
    local query_port=$3
    local file_port=$4
    local exposed_voice_port=$5
    local exposed_query_port=$6
    local exposed_file_port=$7

    echo "Starting $name container..."
    remove_existing_container "$name"

    docker run -d \
        --name "$name" \
        --restart always \
        -e VOICE_PORT="$voice_port" \
        -e QUERY_PORT="$query_port" \
        -e FILE_PORT="$file_port" \
        -p "$exposed_voice_port:$voice_port/udp" \
        -p "$exposed_query_port:$query_port" \
        -p "$exposed_file_port:$file_port" \
        -v "$(pwd)/persistence/$name/data:/teaspeak/data" \
        -v "$(pwd)/persistence/$name/config:/teaspeak/config" \
        -v "$(pwd)/persistence/$name/logs:/teaspeak/logs" \
        teaspeak

    if ! docker ps | grep -q "$name"; then
        echo "Error: Container $name failed to start"
        docker logs "$name"
        exit 1
    fi
}

# Function to verify containers are running
function verify_containers {
    echo "Verifying containers..."
    for container in "$TEASPEAK1_NAME" "$TEASPEAK2_NAME"; do
        if ! docker ps | grep -q "$container"; then
            echo "Error: $container is not running"
            docker logs "$container"
            exit 1
        fi
        echo "$container is running successfully"
    done
}

# Function to configure firewall
function configure_firewall {
    echo "Configuring firewall rules..."
    
    # Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable
    fi
    
    # Allow TeaSpeak 1 ports
    sudo ufw allow 9987/udp comment 'TeaSpeak 1 Voice'
    sudo ufw allow 10101/tcp comment 'TeaSpeak 1 Query'
    sudo ufw allow 30303/tcp comment 'TeaSpeak 1 File'
    
    # Allow TeaSpeak 2 ports
    sudo ufw allow 9988/udp comment 'TeaSpeak 2 Voice'
    sudo ufw allow 10102/tcp comment 'TeaSpeak 2 Query'
    sudo ufw allow 30304/tcp comment 'TeaSpeak 2 File'
    
    # Reload firewall
    sudo ufw reload
    
    echo "Firewall configured successfully"
    sudo ufw status numbered | grep -E '9987|9988|10101|10102|30303|30304'
}

# Main script execution
echo "Starting TeaSpeak deployment..."

# Check prerequisites
check_docker_installed
check_docker_permissions

# Configure firewall
configure_firewall

# Create directories
create_directories

# Build image
build_image

# Run containers
run_teaspeak_container "$TEASPEAK1_NAME" 9987 10101 30303 9987 10101 30303
run_teaspeak_container "$TEASPEAK2_NAME" 9987 10101 30303 9988 10102 30304

# Verify deployment
verify_containers

echo "Deployment completed successfully"

# Show container status
echo -e "\nContainer Status:"
docker ps | grep "teaspeak"

# Show firewall status
echo -e "\nFirewall Status for TeaSpeak ports:"
sudo ufw status | grep -E '9987|9988|10101|10102|30303|30304'