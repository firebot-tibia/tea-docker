# TEA-DOCKER

A Docker-based setup for running multiple TeaSpeak servers with automated database management.

## Project Structure

```plaintext
TEA-DOCKER/
├── data/
│   └── sql/
│       ├── TeaData.sqlite
│       ├── TeaData.sqlite-shm
│       └── TeaData.sqlite-wal
├── scripts/
│   └── scripts for help
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── railway.toml
└── README.md
```

## Features

- Multiple TeaSpeak server instances
- Isolated network configuration
- Volume persistence for each server
- Automated database import tool
- Time zone configuration (America/Sao_Paulo)

## Prerequisites

- Docker
- Docker Compose
- Git
- Bash shell

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd tea-docker
```

2. Configure the environment:
- Each server has its own set of volumes for data persistence
- Network configuration is isolated for each instance
- Default timezone is set to America/Sao_Paulo

3. Build and start the containers:
```bash
docker-compose up -d
```

## Server Configuration

The setup includes two TeaSpeak servers with different port configurations:

### Server 1
- Voice: 9987 (UDP/TCP)
- Server Query: 10101
- File Transfer: 30303

### Server 2
- Voice: 9988 (UDP/TCP)
- Server Query: 10102
- File Transfer: 30304

## Database Management

### Import Script

The `import-backup.sh` script facilitates database imports to either server instance.

#### Usage:
```bash
./scripts/import-backup.sh <server-number>
```

#### Parameters:
- `server-number`: Target server (1 or 2)

#### Features:
- Automatic backup of existing database
- Safe service shutdown during import
- Proper permission management
- Cleanup of temporary files
- Container restart after import

#### Example:
```bash
# Example usages:
./scripts/import-backup.sh teaspeak-server-1
./scripts/import-backup.sh my-custom-teaspeak
./scripts/import-backup.sh any-container-name
```

## Volume Management

Each server maintains separate volumes for:
- Certificates
- Configuration
- Database
- Files
- Logs
- Crash dumps

## Network Configuration

The servers operate on an isolated bridge network with fixed IPs:
- Server 1: 192.168.90.2
- Server 2: 192.168.90.3


# Usage Examples

# Run permissions to all scripts
chmod +x scripts/*.sh

# Import database
./scripts/main.sh import <container-name>

