#!/bin/bash
set -e

echo "=== Current Directory ==="
pwd

echo "=== Directory Content of /ts ==="
ls -la /ts

echo "=== All Executable Files ==="
find /ts -type f -executable

echo "=== Full Directory Structure ==="
ls -R /ts

# Verificar portas abertas
netstat -tulpn | grep LISTEN

# Verificar logs do TeaSpeak
tail -f /ts/logs/teaspeak.log

# Verificar se o processo está rodando
ps aux | grep TeaSpeak

echo "=== Starting TeaSpeak ==="
cd /ts
exec ./TeaSpeakServer -Pgeneral.database.url=sqlite://database/TeaData.sqlite