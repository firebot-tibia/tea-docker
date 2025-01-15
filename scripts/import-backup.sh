#!/bin/bash

show_usage() {
    echo "Usage: ./import-backup.sh <container-name>"
    echo "Example: ./import-backup.sh teaspeak-server-1"
    echo "         ./import-backup.sh my-custom-teaspeak"
}

if [ -z "$1" ]; then
    echo "Error: Container name not provided"
    show_usage
    exit 1
fi

CONTAINER_NAME="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if ! docker ps | grep -q ${CONTAINER_NAME}; then
    echo "Error: Container ${CONTAINER_NAME} is not running"
    echo "Running containers:"
    docker ps --format "{{.Names}}"
    exit 1
fi

TEASPEAK_UID=$(docker exec ${CONTAINER_NAME} stat -c '%u' /teaspeak/database || echo "1000")
TEASPEAK_GID=$(docker exec ${CONTAINER_NAME} stat -c '%g' /teaspeak/database || echo "1000")

echo "Using TeaSpeak UID:GID = ${TEASPEAK_UID}:${TEASPEAK_GID}"

echo "Creating temporary directory..."
docker exec ${CONTAINER_NAME} sh -c "mkdir -p /tmp/import && chown ${TEASPEAK_UID}:${TEASPEAK_GID} /tmp/import"

echo "Copying SQL files to container..."
for file in TeaData.sqlite TeaData.sqlite-shm TeaData.sqlite-wal; do
    if [ -f "./data/sql/$file" ]; then
        docker cp "./data/sql/$file" "${CONTAINER_NAME}:/tmp/import/"
        docker exec ${CONTAINER_NAME} chown ${TEASPEAK_UID}:${TEASPEAK_GID} "/tmp/import/$file"
    else
        echo "Warning: $file not found in ./data/sql/"
    fi
done

echo "Stopping TeaSpeak service..."
docker exec ${CONTAINER_NAME} sh -c "if pgrep teaspeak; then pkill teaspeak; sleep 2; fi"

echo "Backing up existing database..."
docker exec --user ${TEASPEAK_UID}:${TEASPEAK_GID} ${CONTAINER_NAME} sh -c "cd /teaspeak/database && \
    if [ -f TeaData.sqlite ]; then \
        tar czf database_backup_${TIMESTAMP}.tar.gz TeaData.sqlite*; \
    fi"

echo "Importing new database files..."
docker exec --user ${TEASPEAK_UID}:${TEASPEAK_GID} ${CONTAINER_NAME} sh -c "cp /tmp/import/TeaData.sqlite* /teaspeak/database/ 2>/dev/null || true"

echo "Setting permissions..."
docker exec ${CONTAINER_NAME} sh -c "find /teaspeak/database -name 'TeaData.sqlite*' -exec chown ${TEASPEAK_UID}:${TEASPEAK_GID} {} \; 2>/dev/null || true"
docker exec ${CONTAINER_NAME} sh -c "find /teaspeak/database -name 'TeaData.sqlite*' -exec chmod 644 {} \; 2>/dev/null || true"

echo "Cleaning up..."
docker exec ${CONTAINER_NAME} rm -rf /tmp/import

echo "Restarting container..."
docker restart ${CONTAINER_NAME}

echo "Import completed successfully for container ${CONTAINER_NAME}!"