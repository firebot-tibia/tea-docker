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

# Add this function to your script
function check_network_config {
    echo "Checking network configuration..."
    
    # Check if system is allowing IPv6
    if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
        echo "Temporarily enabling IPv6..."
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
    fi
    
    # Ensure proper network bindings
    sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
    
    # Apply changes
    sudo sysctl -p
}

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
        --network host \  # Add this line
        -e VOICE_PORT="$voice_port" \
        -e QUERY_PORT="$query_port" \
        -e FILE_PORT="$file_port" \
        -e TS3SERVER_LICENSE="accept" \
        --ulimit nofile=32768:32768 \
        --cap-add=NET_ADMIN \  # Add this line
        --cap-add=NET_BIND_SERVICE \  # Add this line
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

function verify_server_connectivity {
    local name=$1
    local query_port=$2
    
    echo "Verifying $name server connectivity..."
    # Wait for server to fully start
    sleep 10
    
    # Try to connect to query port
    if ! nc -z localhost "$query_port"; then
        echo "Warning: Server $name not responding on port $query_port"
        docker logs "$name"
    else
        echo "Server $name is accepting connections"
    fi
}

# Add this to your create_directories function
function fix_permissions {
    echo "Fixing permissions..."
    sudo chown -R 1000:1000 ./persistence
    sudo chmod -R 755 ./persistence
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
        echo "Enabling UFW firewall..."
        sudo ufw --force enable
    fi
    
    echo "Setting up explicit firewall rules..."
    
    # Allow TeaSpeak 1 (ts3) ports
    sudo ufw allow from any to any port 9987 proto udp comment 'TeaSpeak 1 Voice'
    sudo ufw allow from any to any port 10101 proto tcp comment 'TeaSpeak 1 Query'
    sudo ufw allow from any to any port 30303 proto tcp comment 'TeaSpeak 1 File'
    
    # Allow TeaSpeak 2 (ourobra) ports
    sudo ufw allow from any to any port 9988 proto udp comment 'TeaSpeak 2 Voice'
    sudo ufw allow from any to any port 10102 proto tcp comment 'TeaSpeak 2 Query'
    sudo ufw allow from any to any port 30304 proto tcp comment 'TeaSpeak 2 File'
    
    # Reload firewall
    echo "Reloading firewall rules..."
    sudo ufw reload
    
    # Display firewall status
    echo "Current firewall rules:"
    sudo ufw status verbose | grep -E '9987|9988|10101|10102|30303|30304'
    
    # Test port accessibility
    echo "Testing port accessibility..."
    which nc >/dev/null || sudo apt-get install -y netcat
    
    echo "Testing UDP ports..."
    nc -uvz localhost 9987 &>/dev/null && echo "Port 9987 (UDP) is open" || echo "Port 9987 (UDP) is closed"
    nc -uvz localhost 9988 &>/dev/null && echo "Port 9988 (UDP) is open" || echo "Port 9988 (UDP) is closed"
    
    echo "Testing TCP ports..."
    nc -zvw3 localhost 10101 &>/dev/null && echo "Port 10101 (TCP) is open" || echo "Port 10101 (TCP) is closed"
    nc -zvw3 localhost 10102 &>/dev/null && echo "Port 10102 (TCP) is open" || echo "Port 10102 (TCP) is closed"
    nc -zvw3 localhost 30303 &>/dev/null && echo "Port 30303 (TCP) is open" || echo "Port 30303 (TCP) is closed"
    nc -zvw3 localhost 30304 &>/dev/null && echo "Port 30304 (TCP) is open" || echo "Port 30304 (TCP) is closed"
}

# Add this new function to verify external access
function verify_external_access {
    echo "Checking external IP address..."
    EXTERNAL_IP=$(curl -s ifconfig.me)
    echo "External IP: $EXTERNAL_IP"
    
    echo "Testing external port accessibility..."
    echo "Please wait, this may take a moment..."
    
    for port in 9987 9988; do
        if nc -uvz -w 5 $EXTERNAL_IP $port 2>/dev/null; then
            echo "UDP Port $port is accessible from outside"
        else
            echo "Warning: UDP Port $port might be blocked"
        fi
    done
    
    for port in 10101 10102 30303 30304; do
        if nc -zvw3 $EXTERNAL_IP $port 2>/dev/null; then
            echo "TCP Port $port is accessible from outside"
        else
            echo "Warning: TCP Port $port might be blocked"
        fi
    done
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
fix_permissions

# Build image
build_image

# Run containers
run_teaspeak_container "$TEASPEAK1_NAME" 9987 10101 30303 9987 10101 30303
run_teaspeak_container "$TEASPEAK2_NAME" 9987 10101 30303 9988 10102 30304

# Verify deployment
verify_containers

# Verify connectivity
verify_server_connectivity "$TEASPEAK1_NAME" 10101
verify_server_connectivity "$TEASPEAK2_NAME" 10102

# Verify external access
verify_external_access

# Add after configure_firewall
check_network_config

echo "Deployment completed successfully"

# Show status
echo -e "\nContainer Status:"
docker ps | grep "teaspeak"

echo -e "\nFirewall Status:"
sudo ufw status | grep -E '9987|9988|10101|10102|30303|30304'

echo -e "\nConnection Information:"
echo "TeaSpeak 1 (ts3): $EXTERNAL_IP:9987"
echo "TeaSpeak 2 (ourobra): $EXTERNAL_IP:9988"