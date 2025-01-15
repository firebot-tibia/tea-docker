#!/bin/bash

show_usage() {
    echo "Usage: ./export-backup.sh <container-name> <local-backup-path>"
    echo "Example: ./export-backup.sh teaspeak-server-1 ./backups"
}

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing parameters"
    show_usage
    exit 1
fi

CONTAINER_NAME="$1"
BACKUP_PATH="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "${BACKUP_PATH}"

echo "Creating backup in container..."
docker exec ${CONTAINER_NAME} sh -c "mkdir -p /teaspeak/database/backups && \
    cd /teaspeak/database && \
    tar czf backups/teaspeak_backup_${TIMESTAMP}.tar.gz TeaData.sqlite*"

echo "Exporting backup to local machine..."
docker cp ${CONTAINER_NAME}:/teaspeak/database/backups/teaspeak_backup_${TIMESTAMP}.tar.gz "${BACKUP_PATH}/"

echo "Backup exported successfully to ${BACKUP_PATH}/teaspeak_backup_${TIMESTAMP}.tar.gz"