#!/bin/bash

sudo service cron start
sudo -u teaspeak crontab /etc/cron.d/teaspeak-backup
exec ./TeaSpeakServer "$@"