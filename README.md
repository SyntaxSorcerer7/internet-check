# Internet-Verbindungsmonitor 🌐

Ein containerisiertes Internet-Monitoring-Tool, das die Verfügbarkeit Ihrer Internetverbindung sowie die Ping-Latenz kontinuierlich überwacht und in einer übersichtlichen Web-Oberfläche mit professionellen Diagrammen visualisiert.

![Internet Monitor Dashboard](https://img.shields.io/badge/Status-Production%20Ready-green)
![Container](https://img.shields.io/badge/Container-Podman%2FDocker-blue)
![Python](https://img.shields.io/badge/Python-3.12-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Release](https://img.shields.io/github/v/release/SyntaxSorcerer7/internet-check)
![Docker](https://img.shields.io/docker/pulls/syntaxsorcerer7/internet-monitor)

## 🚀 Schnellstart

### 📦 Docker Hub (Empfohlen)

```bash
# Direkt vom Docker Hub verwenden
docker run -d --name internet-monitor -p 8000:8000 syntaxsorcerer7/internet-monitor

# Oder mit lokaler Datenpersistierung
docker run -d --name internet-monitor -p 8000:8000 -v $(pwd)/data:/app syntaxsorcerer7/internet-monitor
```

### 🏗️ Lokaler Build

```bash
# Repository klonen
git clone <repository-url>
cd internet-check

# Mit einem Befehl starten
./build-and-run.sh
```

**Web-Interface:** <http://localhost:8000>

## 📊 Features

### 📈 Drei Monitoring-Ebenen

- **📍 Detaillierter Verlauf**: Minutengenaue Aufzeichnung aller Connectivity-Tests inklusive Ping-Latenz
- **⏰ 24-Stunden-Übersicht**: Stündliche Aggregation mit Verfügbarkeitsprozenten
- **📅 30-Tage-Übersicht**: Tägliche Langzeittrends für SLA-Monitoring

### 🎯 Professionelle Verfügbarkeitsstufen

- 🟢 **Exzellent** (≥99,9%): Enterprise-Grade Verfügbarkeit
- 🟡 **Gut** (98,0-99,8%): Akzeptable Performance mit gelegentlichen Unterbrechungen  
- 🔴 **Problematisch** (<98%): Häufige Ausfälle, sofortige Maßnahmen erforderlich
- 🔵 **Keine Daten**: Noch keine Messwerte verfügbar

### ⚡ Technische Highlights

- **Echtzeit-Updates**: Automatische Diagramm-Aktualisierung alle 60 Sekunden
- **Responsive Design**: Optimiert für Desktop, Tablet und Mobile
- **Persistente Speicherung**: SQLite-Datenbank mit automatischem Cleanup
- **Container-Ready**: Podman/Docker-basiert ohne komplexe Abhängigkeiten
- **Hochperformant**: Minimaler Ressourcenverbrauch durch Alpine Linux
- **Ping-Latenzmessung**: ICMP-Ping zur Erfassung der aktuellen Latenz und Anzeige im Dashboard

## ⚙️ Konfiguration

Alle Einstellungen erfolgen über Umgebungsvariablen:

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `CHECK_INTERVAL_SEC` | `20` | Intervall zwischen Connectivity-Tests (Sekunden) |
| `RETENTION_DAYS` | `60` | Aufbewahrungsdauer der Messdaten (Tage) |
| `TEST_URL` | `https://1.1.1.1` | Ziel-URL für Connectivity-Tests |
| `DB_PATH` | `data.db` | Pfad zur SQLite-Datenbankdatei |

### 🛠️ Erweiterte Konfiguration

```bash
# Hochfrequentes Monitoring (alle 10 Sekunden)
podman run -d \
  -p 8000:8000 \
  -e CHECK_INTERVAL_SEC=10 \
  -e RETENTION_DAYS=90 \
  internet-monitor

# Monitoring verschiedener Ziele
podman run -d -p 8001:8000 -e TEST_URL=https://google.com --name monitor-google internet-monitor
podman run -d -p 8002:8000 -e TEST_URL=https://github.com --name monitor-github internet-monitor
```

## 📁 Projektstruktur

```text
internet-check/
├── monitor.py              # Python-Backend (Flask-Server + Monitoring-Logic)
├── templates/
│   └── index.html         # HTML-Frontend mit Chart.js Visualisierungen
├── Dockerfile              # Container-Definition (Alpine Linux + Python)
├── build-and-run.sh       # One-Click Start-Script (Podman/Docker)
├── auto-update.sh         # Automatisches Update-Script
├── data.db                # SQLite-Datenbank (wird beim ersten Start erstellt)
└── README.md              # Diese Dokumentation
```

## 🏷️ Releases & Versioning

Das Projekt verwendet **automatisches Semantic Versioning** mit GitHub Actions:

### Automatische Releases
- 🔄 **Jeder Push zur main-Branch** → Neue Patch-Version (z.B. v1.0.1)
- 🐳 **Docker Images** → Automatisch auf Docker Hub gepusht
- 📦 **GitHub Releases** → Mit Changelog und Download-Links

### Manueller Release
```bash
# Interaktives Release-Script
./release.sh

# Oder über GitHub Actions UI
# Wähle: patch (1.0.1) | minor (1.1.0) | major (2.0.0)
```

### Version-Tags verwenden
```bash
# Neueste Version (empfohlen für Entwicklung)
docker pull syntaxsorcerer7/internet-monitor:latest

# Spezifische Version (empfohlen für Produktion)
docker pull syntaxsorcerer7/internet-monitor:1.2.3

# Major.Minor (automatische Patch-Updates)
docker pull syntaxsorcerer7/internet-monitor:1.2
```

📖 **Mehr Details:** Siehe [VERSIONING.md](VERSIONING.md) und [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

## 🛠️ Technische Details

## 🏗️ Architektur

Das Projekt ist jetzt modular strukturiert:

- **Backend** (`monitor.py`): Python Flask-Server mit SQLite-Integration
  - HTTP-Monitoring mit konfigurierbaren Intervallen
  - REST-API für Datenabfrage (`/data` Endpoint)
  - Automatische Datenbereinigung nach konfigurierbarer Retention
  - Multithreading für non-blocking Monitoring

- **Frontend** (`templates/index.html`): Responsive Web-Interface
  - Chart.js für professionelle Datenvisualisierung
  - Echtzeit-Updates via AJAX alle 60 Sekunden
  - Mobile-optimiertes Design
  - Timezone-aware Darstellung (UTC → Ortszeit)

- **Container** (`Dockerfile`): Schlanke Alpine Linux-Basis
  - Python 3.12 mit minimalen Dependencies (Flask, Requests)
  - UTC-Zeitzone für konsistente Timestamps
  - Automatisches Kopieren der Quellcode-Dateien
  - Multi-Platform Support (AMD64, ARM64)

- **CI/CD** (`.github/workflows/`): Automatisierte Container-Builds
  - Automatischer Build und Push zu Docker Hub bei commits
  - Multi-Platform Builds (AMD64, ARM64)
  - Automatische Tag-Verwaltung und Versionierung
  - Docker Hub Beschreibung wird automatisch aktualisiert

### 📊 Datenmodell

Die Status-Tabelle speichert neben dem Onlinestatus auch die gemessene Ping-Latenz:

```sql
CREATE TABLE status (
    ts   INTEGER PRIMARY KEY,  -- Unix-Timestamp (Sekunden seit 1970)
    up   INTEGER,              -- 1 = online, 0 = offline
    ping REAL                  -- gemessene Ping-Latenz in Millisekunden
);
```

### 🔗 API-Endpunkte

- `GET /` - Responsive Web-Dashboard
- `GET /data` - JSON-API mit Roh- und Aggregationsdaten inklusive Ping-Latenzen (`pings`)

### 🛰️ Monitoring-Algorithmus

1. **HTTP-Test**: GET-Request an konfigurierte URL
2. **Ping-Messung**: ICMP-Ping zur Ermittlung der Latenz
3. **Timeout-Handling**: 5 Sekunden maximale Wartezeit
4. **Bewertung**: HTTP 2xx = Online | Timeout/Error oder fehlender Ping = Offline
5. **Speicherung**: Timestamp + Status + Ping in SQLite
6. **Retention**: Automatisches Cleanup alter Daten

## 💡 Anwendungsfälle

- **🏠 Heimnetzwerk**: Überwachung der DSL/Glasfaser-Verbindung
- **🏢 Büronetzwerke**: Dokumentation von Provider-Ausfällen  
- **📋 SLA-Monitoring**: Nachweis der Verfügbarkeit für Verträge
- **🔧 Troubleshooting**: Root-Cause-Analyse bei Verbindungsproblemen
- **📈 Kapazitätsplanung**: Langzeit-Trendanalyse für Upgrades

## 🚀 Erweiterte Nutzung

### 📦 Multi-Instance Deployment

```bash
# Primäre Verbindung (Cloudflare DNS)
podman run -d --name monitor-primary -p 8000:8000 internet-monitor

# Backup-Verbindung (Google DNS)  
podman run -d --name monitor-backup -p 8001:8000 \
  -e TEST_URL=https://8.8.8.8 internet-monitor

# Provider-Website
podman run -d --name monitor-isp -p 8002:8000 \
  -e TEST_URL=https://www.telekom.de internet-monitor
```

### 💾 Datenmanagement

```bash
# Datenbank-Backup
podman exec monitor-primary cp /app/data.db /tmp/
podman cp monitor-primary:/tmp/data.db ./backup_$(date +%Y%m%d).db

# CSV-Export für Excel-Analyse
  podman exec monitor-primary sqlite3 /app/data.db \
    "SELECT datetime(ts, 'unixepoch') as timestamp,
            CASE up WHEN 1 THEN 'Online' ELSE 'Offline' END as status,
            ping
     FROM status ORDER BY ts;" \
    -header -csv > connectivity_report.csv

# Statistiken abrufen
  podman exec monitor-primary sqlite3 /app/data.db \
    "SELECT
       COUNT(*) as total_checks,
       SUM(up) as successful_checks,
       ROUND(SUM(up) * 100.0 / COUNT(*), 2) as uptime_percentage,
       ROUND(AVG(ping), 2) as avg_ping_ms
     FROM status WHERE ts >= strftime('%s', 'now', '-24 hours');"
```

## 📊 SLA-Referenztabelle

| Verfügbarkeit | Ausfallzeit/Jahr | Ausfallzeit/Monat | Ausfallzeit/Tag | Bewertung |
|---------------|------------------|-------------------|-----------------|-----------|
| 99,99% | 52,6 Minuten | 4,4 Minuten | 8,6 Sekunden | 🟢 Exzellent |
| 99,9% | 8,77 Stunden | 43,8 Minuten | 1,44 Minuten | 🟢 Exzellent |
| 99,5% | 43,8 Stunden | 3,65 Stunden | 7,2 Minuten | 🟡 Gut |
| 99,0% | 87,7 Stunden | 7,31 Stunden | 14,4 Minuten | 🟡 Gut |
| 98,0% | 175 Stunden | 14,6 Stunden | 28,8 Minuten | 🔴 Problematisch |

## 🚨 Troubleshooting

### Container startet nicht

```bash
# Logs prüfen  
podman logs <container-name>

# Port-Konflikte checken
netstat -tulpn | grep :8000
lsof -i :8000

# Container-Status prüfen
podman ps -a
```

### Keine Daten sichtbar

- **Warten**: Mindestens 1-2 Minuten nach dem Start warten
- **Netzwerk**: Container-Netzwerkverbindung prüfen
- **URL**: TEST_URL-Erreichbarkeit validieren
- **Firewall**: Ausgehende HTTP-Verbindungen erlauben

### Performance-Optimierung

```bash
# Speicherverbrauch reduzieren
-e RETENTION_DAYS=7

# Höhere Frequenz für kritische Systeme  
-e CHECK_INTERVAL_SEC=5

# Ressourcen-Limits setzen
podman run --memory=128m --cpus=0.5 internet-monitor
```

### Datenbank-Wartung

```bash
# Datenbank-Größe prüfen
podman exec monitor-primary du -h /app/data.db

# Manuelle Bereinigung
podman exec monitor-primary sqlite3 /app/data.db \
  "DELETE FROM status WHERE ts < strftime('%s', 'now', '-7 days');"

# Datenbank-Optimierung
podman exec monitor-primary sqlite3 /app/data.db "VACUUM;"
```

## 🤝 Support & Entwicklung

### 🐛 Bug Reports

Erstellen Sie ein [GitHub Issue](https://github.com/SyntaxSorcerer7/internet-check/issues) mit:

- Betriebssystem und Version
- Podman/Docker Version  
- Container-Logs (`podman logs <container>`)
- Beschreibung des Problems

### 💡 Feature Requests

Wir freuen uns über Verbesserungsvorschläge! Bitte öffnen Sie ein Issue mit:

- Detaillierte Beschreibung der gewünschten Funktion
- Anwendungsfall/Nutzen
- Optionale Implementierungsideen

### � Entwicklung

```bash
# Development-Setup
git clone https://github.com/SyntaxSorcerer7/internet-check.git
cd internet-check

# Lokale Entwicklung
podman build -t internet-monitor-dev .
podman run --rm -p 8000:8000 -v $(pwd):/app internet-monitor-dev

# Tests ausführen (falls vorhanden)
podman exec -it <container> python -m pytest
```

## 📝 Lizenz

Dieses Projekt steht unter der **MIT-Lizenz**. Siehe [LICENSE](LICENSE) für Details.

## 🌟 Mitwirkende

Dank an alle Entwickler, die zu diesem Projekt beitragen!

---

Made with ❤️ for reliable internet monitoring
