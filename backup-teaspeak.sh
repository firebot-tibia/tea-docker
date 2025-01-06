#!/bin/bash
# save as backup-teaspeak.sh

# Configurações
CONTAINER_NAME=$1  # Nome do container (teaspeak1 ou teaspeak2)
BACKUP_DIR="/teaspeak/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_PATH="/teaspeak/data/teaspeak.db"

# Cria backup do banco SQLite usando o comando sqlite3
docker exec $CONTAINER_NAME bash -c "
    if [ -f $DB_PATH ]; then
        echo '.backup \"$BACKUP_DIR/teaspeak_$DATE.db\"' | sqlite3 $DB_PATH
        # Compacta o backup
        cd $BACKUP_DIR
        tar -czf teaspeak_$DATE.tar.gz teaspeak_$DATE.db
        rm teaspeak_$DATE.db
        
        # Mantém apenas os últimos 5 backups
        ls -t $BACKUP_DIR/teaspeak_*.tar.gz | tail -n +6 | xargs -r rm
        
        echo 'Backup completed successfully'
    else
        echo 'Database file not found'
    fi
"