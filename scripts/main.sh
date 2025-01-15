#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    echo -e "${YELLOW}TeaSpeak Docker Management Script${NC}"
    echo ""
    echo "Usage: ./main.sh [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  import [container-name]                     - Import database to container"
    echo "  export [container-name] [local-path]        - Export backup from container"
    echo "  backup [container-name]                     - Create backup inside container"
    echo "  list-backups [container-name]              - List all backups in container"
    echo "  configure-ticks [container-name]           - Configure ticking settings"
    echo "  status [container-name]                    - Show container status"
    echo "  logs [container-name]                      - Show container logs"
    echo "  cron-config [container-name]               - Configure automated backups"
    echo ""
    echo "Examples:"
    echo "  ./main.sh import teaspeak-server-1"
    echo "  ./main.sh export teaspeak-server-1 ./my-backups"
    echo "  ./main.sh backup teaspeak-server-1"
    echo "  ./main.sh status teaspeak-server-1"
}

check_container() {
    if ! docker ps | grep -q "$1"; then
        echo -e "${RED}Error: Container $1 is not running${NC}"
        echo "Running containers:"
        docker ps --format "{{.Names}}"
        exit 1
    fi
}

import_database() {
    echo -e "${GREEN}Importing database to $1...${NC}"
    ./scripts/import-backup.sh "$1"
}

export_backup() {
    echo -e "${GREEN}Exporting backup from $1 to $2...${NC}"
    ./scripts/export-backup.sh "$1" "$2"
}

create_backup() {
    echo -e "${GREEN}Creating backup in container $1...${NC}"
    docker exec "$1" /teaspeak/scripts/automated-backup.sh
}

list_backups() {
    echo -e "${GREEN}Listing backups in container $1...${NC}"
    docker exec "$1" ls -lah /teaspeak/database/backups
}

configure_ticks() {
    echo -e "${GREEN}Configuring ticking settings for $1...${NC}"
    docker exec "$1" mkdir -p /teaspeak/config
    
    docker exec "$1" bash -c 'cat > /teaspeak/config/config.yml << EOL
client:
  tick:
    warning_threshold: 5000
    interval: 100
EOL'
    
    echo -e "${GREEN}Ticking configuration updated. Restarting container...${NC}"
    docker restart "$1"
}

show_status() {
    echo -e "${GREEN}Status for container $1:${NC}"
    docker ps --filter "name=$1" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

show_logs() {
    echo -e "${GREEN}Logs for container $1:${NC}"
    docker logs --tail 100 "$1"
}

configure_cron() {
    echo -e "${GREEN}Configuring automated backups for $1...${NC}"
    docker exec "$1" bash -c 'cat > /etc/cron.d/teaspeak-backup << EOL
0 3 * * 0,3 /teaspeak/scripts/automated-backup.sh >> /teaspeak/database/backups/cron.log 2>&1
EOL'
    docker exec "$1" chmod 0644 /etc/cron.d/teaspeak-backup
    docker exec "$1" crontab /etc/cron.d/teaspeak-backup
    echo -e "${GREEN}Cron configuration complete. Backups will run at 3 AM on Wednesdays and Sundays.${NC}"
}

case "$1" in
    "import")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        import_database "$2"
        ;;
    "export")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Error: Container name and local path required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        export_backup "$2" "$3"
        ;;
    "backup")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        create_backup "$2"
        ;;
    "list-backups")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        list_backups "$2"
        ;;
    "configure-ticks")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        configure_ticks "$2"
        ;;
    "status")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        show_status "$2"
        ;;
    "logs")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        show_logs "$2"
        ;;
    "cron-config")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            show_usage
            exit 1
        fi
        check_container "$2"
        configure_cron "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac