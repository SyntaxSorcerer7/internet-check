#!/bin/bash
shopt -s expand_aliases
alias docker='podman'

docker stop monitor
docker rm monitor
docker build -t internet-monitor .
docker run -d --name monitor -p 8000:8000 internet-monitor