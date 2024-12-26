#!/bin/bash

sed -i "s/port = 9987/port = $VOICE_PORT/" config.yml
sed -i "s/port = 10101/port = $QUERY_PORT/" config.yml
sed -i "s/port = 30303/port = $FILE_PORT/" config.yml

./TeaSpeakServer