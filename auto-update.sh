#!/bin/bash

# ================================================================
# Auto-Update-Skript für Internet Monitor
# ================================================================
# Prüft regelmäßig auf Git-Updates und startet bei Änderungen
# das Build-und-Start-Skript neu.

# Konfiguration
CHECK_INTERVAL=300  # Prüfung alle 5 Minuten (300 Sekunden)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_SCRIPT="$REPO_DIR/build-and-run.sh"
LOG_FILE="$REPO_DIR/auto-update.log"
PID_FILE="$REPO_DIR/auto-update.pid"

# Logging-Funktion
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Prüfen ob bereits eine Instanz läuft
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Auto-Update läuft bereits (PID: $OLD_PID)"
        exit 1
    else
        rm -f "$PID_FILE"
    fi
fi

# PID speichern
echo $$ > "$PID_FILE"

# Aufräumen beim Beenden
cleanup() {
    log "Auto-Update wird beendet..."
    rm -f "$PID_FILE"
    exit 0
}
trap cleanup SIGTERM SIGINT

log "Auto-Update gestartet (PID: $$)"
log "Repository: $REPO_DIR"
log "Prüfintervall: $CHECK_INTERVAL Sekunden"

# Sicherstellen, dass wir im richtigen Verzeichnis sind
cd "$REPO_DIR" || {
    log "FEHLER: Kann nicht in Repository-Verzeichnis wechseln: $REPO_DIR"
    exit 1
}

# Prüfen ob Git-Repository vorhanden ist
if [ ! -d ".git" ]; then
    log "FEHLER: Kein Git-Repository gefunden in $REPO_DIR"
    exit 1
fi

# Prüfen ob Build-Script vorhanden ist
if [ ! -f "$BUILD_SCRIPT" ]; then
    log "FEHLER: Build-Script nicht gefunden: $BUILD_SCRIPT"
    exit 1
fi

# Aktuellen Git-Hash speichern
get_current_hash() {
    git rev-parse HEAD 2>/dev/null
}

LAST_HASH=$(get_current_hash)
log "Aktueller Git-Hash: $LAST_HASH"

# Hauptschleife
while true; do
    # Git-Repository aktualisieren (fetch)
    log "Prüfe auf Updates..."
    
    if ! git fetch origin 2>&1 | tee -a "$LOG_FILE"; then
        log "WARNUNG: Git fetch fehlgeschlagen"
        sleep "$CHECK_INTERVAL"
        continue
    fi
    
    # Aktuellen Hash mit Remote-Hash vergleichen
    REMOTE_HASH=$(git rev-parse origin/$(git branch --show-current) 2>/dev/null)
    CURRENT_HASH=$(get_current_hash)
    
    if [ "$CURRENT_HASH" != "$REMOTE_HASH" ]; then
        log "Neue Änderungen erkannt!"
        log "Lokal:  $CURRENT_HASH"
        log "Remote: $REMOTE_HASH"
        
        # Repository aktualisieren
        log "Führe git pull aus..."
        if git pull origin $(git branch --show-current) 2>&1 | tee -a "$LOG_FILE"; then
            NEW_HASH=$(get_current_hash)
            log "Update erfolgreich. Neuer Hash: $NEW_HASH"
            
            # Build-Script ausführen
            log "Starte Build-und-Deploy-Prozess..."
            if bash "$BUILD_SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
                log "Build-und-Deploy erfolgreich abgeschlossen"
                LAST_HASH="$NEW_HASH"
            else
                log "FEHLER: Build-und-Deploy fehlgeschlagen"
            fi
        else
            log "FEHLER: Git pull fehlgeschlagen"
        fi
    else
        log "Keine Änderungen gefunden"
    fi
    
    # Warten bis zur nächsten Prüfung
    log "Warte $CHECK_INTERVAL Sekunden bis zur nächsten Prüfung..."
    sleep "$CHECK_INTERVAL"
done
