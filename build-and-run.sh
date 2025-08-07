#!/bin/bash
shopt -s expand_aliases
alias docker='podman'

# Aktuelles Verzeichnis für Datenbank-Volume
CURRENT_DIR="$(pwd)"

# Container stoppen und entfernen
docker stop monitor 2>/dev/null
docker rm monitor 2>/dev/null

# Image neu bauen
docker build -t internet-monitor .

# Container mit Volume für Datenbank starten
# Die Datenbank wird im aktuellen Verzeichnis gespeichert
docker run -d --name monitor \
  -p 8000:8000 \
  -v "$CURRENT_DIR:/data" \
  -e DB_PATH="/data/data.db" \
  internet-monitor