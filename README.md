# Internet-Verbindungsmonitor 🌐

Ein containerisiertes Internet-Monitoring-Tool, das die Verfügbarkeit Ihrer Internetverbindung kontinuierlich überwacht und in einer übersichtlichen Web-Oberfläche visualisiert.

## 📊 Features

- **Kontinuierliches Monitoring**: Automatische Überprüfung der Internetverbindung in konfigurierbaren Intervallen
- **Drei Ansichtsebenen**:
  - Detaillierter Verlauf mit minutengenauer Auflösung
  - 24-Stunden-Übersicht mit stündlicher Aggregation
  - 30-Tage-Übersicht mit täglicher Aggregation
- **Professionelle Verfügbarkeitsstufen**:
  - 🟢 **Exzellent** (≥99,9%): SLA-konforme Verfügbarkeit
  - 🟡 **Gut** (98,0-99,8%): Akzeptable Verfügbarkeit mit gelegentlichen Unterbrechungen
  - 🔴 **Problematisch** (<98%): Häufige Ausfälle, Intervention erforderlich
  - 🔵 **Keine Daten**: Noch keine Messwerte verfügbar
- **Echtzeit-Updates**: Automatische Aktualisierung der Diagramme alle 60 Sekunden
- **Responsive Design**: Optimiert für Desktop und mobile Geräte
- **SQLite-Datenbank**: Persistente Speicherung aller Messwerte
- **Docker-basiert**: Einfache Bereitstellung ohne komplexe Abhängigkeiten

## 🚀 Schnellstart

### Mit Docker (empfohlen)

```bash
# Repository klonen
git clone <repository-url>
cd internet-check

# Container bauen und starten
./build-and-run.sh
```

Die Web-Oberfläche ist dann unter <http://localhost:8000> erreichbar.

### Manueller Start

```bash
# Python-Abhängigkeiten installieren
pip install flask requests

# Monitoring-Script aus dem Dockerfile extrahieren und ausführen
# (siehe Dockerfile für den kompletten Python-Code)
python monitor.py
```

## ⚙️ Konfiguration

Das Tool kann über Umgebungsvariablen konfiguriert werden:

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `CHECK_INTERVAL_SEC` | `60` | Intervall zwischen Connectivity-Checks in Sekunden |
| `RETENTION_DAYS` | `30` | Aufbewahrungsdauer der Messdaten in Tagen |
| `TEST_URL` | `https://1.1.1.1` | URL für Connectivity-Tests (Cloudflare DNS) |
| `DB_PATH` | `data.db` | Pfad zur SQLite-Datenbankdatei |

### Beispiel mit benutzerdefinierten Einstellungen

```bash
docker run -d \
  -p 8000:8000 \
  -v $(pwd)/data:/app/data \
  -e CHECK_INTERVAL_SEC=30 \
  -e RETENTION_DAYS=60 \
  -e TEST_URL=https://google.com \
  -e DB_PATH=/app/data/monitoring.db \
  internet-monitor
```

## 📁 Projektstruktur

```text
internet-check/
├── Dockerfile              # Container-Definition mit eingebettetem Python-Code
├── build-and-run.sh       # Build- und Start-Script
└── README.md              # Diese Dokumentation
```

## 🛠️ Technische Details

### Architektur

- **Backend**: Python Flask-Webserver
- **Frontend**: Vanilla JavaScript mit Chart.js für Visualisierungen
- **Datenbank**: SQLite für lokale Datenpersistierung
- **Monitoring**: Requests-Library für HTTP-Connectivity-Tests
- **Container**: Alpine Linux mit Python 3.12

### Datenmodell

```sql
CREATE TABLE status (
    ts INTEGER PRIMARY KEY,  -- Unix-Timestamp
    up INTEGER              -- 1=online, 0=offline
);
```

### API-Endpunkte

- `GET /` - Web-Oberfläche (HTML)
- `GET /data` - JSON-API mit aggregierten Messdaten

## 📈 Monitoring-Logik

1. **Connectivity-Test**: HTTP-Request an konfigurierte Test-URL
2. **Timeout**: 5 Sekunden maximale Wartezeit
3. **Bewertung**: Erfolgreiche Requests = Online, Timeouts/Fehler = Offline
4. **Speicherung**: Timestamp und Status in SQLite-Datenbank
5. **Cleanup**: Automatisches Löschen alter Daten basierend auf Retention-Einstellung

## 🎯 Verwendungszwecke

- **Heimnetzwerk-Monitoring**: Überwachung der DSL/Kabel-Verbindung
- **Office-Netzwerke**: Dokumentation von Internetausfällen
- **SLA-Monitoring**: Nachweis der Provider-Verfügbarkeit
- **Troubleshooting**: Identifikation von Verbindungsproblemen
- **Kapazitätsplanung**: Analyse von Ausfallmustern

## 🔧 Erweiterte Nutzung

### Datenexport

```bash
# SQLite-Datenbank direkt abfragen
sqlite3 data.db "SELECT datetime(ts, 'unixepoch'), up FROM status ORDER BY ts;"

# CSV-Export
sqlite3 -header -csv data.db "SELECT * FROM status;" > export.csv
```

### Backup

```bash
# Datenbank-Backup
cp data.db backup_$(date +%Y%m%d).db

# Container-Volume-Backup
docker run --rm -v internet-check_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .
```

### Monitoring von mehreren Verbindungen

Mehrere Container-Instanzen für verschiedene Test-URLs:

```bash
# Primäre Verbindung (Cloudflare)
docker run -d --name monitor-cf -p 8001:8000 -e TEST_URL=https://1.1.1.1 internet-monitor

# Sekundäre Verbindung (Google)
docker run -d --name monitor-google -p 8002:8000 -e TEST_URL=https://8.8.8.8 internet-monitor

# Provider-Website
docker run -d --name monitor-isp -p 8003:8000 -e TEST_URL=https://www.telekom.de internet-monitor
```

## 📊 Verfügbarkeits-Benchmarks

| SLA-Level | Downtime/Jahr | Downtime/Monat | Downtime/Tag |
|-----------|---------------|----------------|--------------|
| 99,9% | 8,77 Stunden | 43,8 Minuten | 1,44 Minuten |
| 99,8% | 17,5 Stunden | 87,7 Minuten | 2,88 Minuten |
| 98,0% | 175 Stunden | 14,6 Stunden | 28,8 Minuten |

## 🚨 Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
docker logs <container-id>

# Port-Konflikte prüfen
netstat -tulpn | grep :8000
```

### Keine Daten sichtbar

- Warten Sie mindestens 1-2 Minuten nach dem Start
- Prüfen Sie die Netzwerkverbindung des Containers
- Überprüfen Sie die TEST_URL-Konfiguration

### Hoher Speicherverbrauch

- Reduzieren Sie RETENTION_DAYS
- Implementieren Sie regelmäßige Datenbank-Cleanups

## 📝 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) für Details.

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder öffnen Sie ein Issue für Verbesserungsvorschläge.

## 📞 Support

Bei Fragen oder Problemen erstellen Sie bitte ein GitHub Issue oder kontaktieren Sie den Projektmaintainer.

---

Made with ❤️ for reliable internet monitoring
