#!/bin/bash

echo "============================================"
echo "Internet Monitor - Build und Deploy"
echo "============================================"

# Aktuelles Verzeichnis für Datenbank-Volume
CURRENT_DIR="$(pwd)"
echo "📂 Arbeitsverzeichnis: $CURRENT_DIR"

# Container stoppen und entfernen
echo "🛑 Stoppe vorhandenen Container..."
if podman stop monitor 2>/dev/null; then
    echo "✅ Container 'monitor' gestoppt"
else
    echo "ℹ️  Kein laufender Container 'monitor' gefunden"
fi

echo "🗑️  Entferne vorhandenen Container..."
if podman rm monitor 2>/dev/null; then
    echo "✅ Container 'monitor' entfernt"
else
    echo "ℹ️  Kein Container 'monitor' zum Entfernen gefunden"
fi

# Image neu bauen
echo "🔨 Baue Docker Image..."
echo "   Lade Basis-Image herunter..."
podman pull python:3.12-alpine
if podman build -t internet-monitor .; then
    echo "✅ Docker Image erfolgreich erstellt"
else
    echo "❌ Fehler beim Erstellen des Docker Images"
    exit 1
fi

# Container mit Volume für Datenbank starten
echo "🚀 Starte Container mit persistenter Datenbank..."
echo "   - Port: 8000:8000"
echo "   - Volume: $CURRENT_DIR:/data"
echo "   - Datenbank: /data/data.db"

if podman run -d --name monitor \
  -p 8000:8000 \
  -v "$CURRENT_DIR:/data" \
  -e DB_PATH="/data/data.db" \
  internet-monitor; then
    echo "✅ Container erfolgreich gestartet"
    echo ""
    echo "🌐 Internet Monitor ist verfügbar unter:"
    echo "   http://localhost:8000"
    echo ""
    echo "📊 Datenbank wird gespeichert in:"
    echo "   $CURRENT_DIR/data.db"
    echo ""
    echo "📋 Container-Status prüfen:"
    echo "   podman logs -f monitor"
    echo "============================================"
else
    echo "❌ Fehler beim Starten des Containers"
    exit 1
fi