#!/bin/bash

BACKUP_DIR="/teaspeak/database/backups"
LOG_FILE="${BACKUP_DIR}/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p ${BACKUP_DIR}

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_FILE}
    echo "$1"
}

log_message "Starting backup..."

if [ ! -f /teaspeak/database/TeaData.sqlite ]; then
    log_message "Error: TeaData.sqlite not found!"
    exit 1
fi

cd /teaspeak/database && \
tar czf ${BACKUP_DIR}/teaspeak_backup_${TIMESTAMP}.tar.gz TeaData.sqlite*

if [ $? -eq 0 ]; then
    log_message "Backup created successfully: teaspeak_backup_${TIMESTAMP}.tar.gz"
else
    log_message "Error creating backup"
    exit 1
fi

BACKUP_SIZE=$(du -h ${BACKUP_DIR}/teaspeak_backup_${TIMESTAMP}.tar.gz | cut -f1)
log_message "Backup size: ${BACKUP_SIZE}"