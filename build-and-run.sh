#!/bin/bash

echo "====================================if $CONTAINER_CMD run -d --name monitor \
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
    echo "   $CONTAINER_CMD logs -f monitor"
    echo "============================================"
else
    echo "❌ Fehler beim Starten des Containers"
    exit 1
firnet Monitor - Build und Deploy"
echo "============================================"

# Container-Runtime automatisch erkennen
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
    echo "🐳 Verwende Docker als Container-Runtime"
elif command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
    echo "🦭 Verwende Podman als Container-Runtime"
else
    echo "❌ Weder Docker noch Podman gefunden!"
    echo "   Bitte installiere Docker oder Podman"
    exit 1
fi

# Aktuelles Verzeichnis für Datenbank-Volume
CURRENT_DIR="$(pwd)"
echo "📂 Arbeitsverzeichnis: $CURRENT_DIR"

# Container stoppen und entfernen
echo "🛑 Stoppe vorhandenen Container..."
if $CONTAINER_CMD stop monitor 2>/dev/null; then
    echo "✅ Container 'monitor' gestoppt"
else
    echo "ℹ️  Kein laufender Container 'monitor' gefunden"
fi

echo "🗑️  Entferne vorhandenen Container..."
if $CONTAINER_CMD rm monitor 2>/dev/null; then
    echo "✅ Container 'monitor' entfernt"
else
    echo "ℹ️  Kein Container 'monitor' zum Entfernen gefunden"
fi

# Image neu bauen
echo "🔨 Baue Container Image..."
echo "   Lade Basis-Image herunter..."
$CONTAINER_CMD pull python:3.12-alpine
if $CONTAINER_CMD build -t internet-monitor .; then
    echo "✅ Container Image erfolgreich erstellt"
else
    echo "❌ Fehler beim Erstellen des Container Images"
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
  --restart unless-stopped \
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
