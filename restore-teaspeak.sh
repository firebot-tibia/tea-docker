#!/bin/bash
# save as restore-teaspeak.sh

CONTAINER_NAME=$1
BACKUP_FILE=$2
DB_PATH="/teaspeak/data/teaspeak.db"

# Verifica se o arquivo de backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Para o container
docker stop $CONTAINER_NAME

# Restaura o backup
docker exec $CONTAINER_NAME bash -c "
    # Extrai o backup
    cd /teaspeak/backups
    tar -xzf $BACKUP_FILE
    
    # Restaura o banco de dados
    cp ${BACKUP_FILE%.tar.gz}.db $DB_PATH
    
    # Limpa arquivos temporários
    rm ${BACKUP_FILE%.tar.gz}.db
"

# Reinicia o container
docker start $CONTAINER_NAME