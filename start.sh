#!/bin/bash
echo "=== Current Directory ==="
pwd

echo "=== Directory Content of /ts ==="
ls -la /ts

echo "=== All Executable Files ==="
find /ts -type f -executable

echo "=== Full Directory Structure ==="
ls -R /ts

echo "=== File Type Check ==="
file /ts/TeaSpeakServer

echo "=== Starting TeaSpeak ==="
cd /ts
exec ./TeaSpeakServer -Pgeneral.database.url=sqlite://database/TeaData.sqlite