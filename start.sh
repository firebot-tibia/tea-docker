#!/bin/bash
set -e

echo "=== Starting TeaSpeak ==="
exec ./TeaSpeakServer -Pgeneral.database.url=sqlite://database/TeaData.sqlite