#!/bin/sh

# export HOST_IP=$(ip -4 route list match 0/0 | awk '{print $3}')
echo "config.yaml"
cat start9/config.yaml

configurator

echo "bwt.env"
cat bwt.env

exec tini bwt
