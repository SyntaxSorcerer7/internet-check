# Internet-Verbindungsmonitor 🌐

Ein containerisiertes Internet-Monitoring-Tool, das die Verfügbarkeit Ihrer Internetverbindung kontinuierlich überwacht und in einer übersichtlichen Web-Oberfläche mit professionellen Diagrammen visualisiert.

![Internet Mo### 🎯 Entwicklung & Anpassungen

Die neue modulare Struktur ermöglicht einfache Anpassungen:

```bash
# Frontend anpassen (HTML/CSS/JavaScript)
nano templates/index.html

# Backend-Logic erweitern  
nano monitor.py

# Container neu bauen nach Änderungen
./build-and-run.sh
```

**Vorteile der neuen Struktur:**

- ✅ Bessere Code-Organisation und Lesbarkeit
- ✅ Separate Bearbeitung von Frontend und Backend
- ✅ Einfachere Versionskontrolle und Debugging
- ✅ Wiederverwendbare Komponenten
- ✅ Standard Flask-Projekt-Layout

### 💻 Lokale Entwicklung

```bash
# Development-Setup
git clone https://github.com/SyntaxSorcerer7/internet-check.git
cd internet-check

# Direkt mit Python ausführen (für Development)
python monitor.py

# Oder im Container mit Volume-Mounting für Live-Reload
podman run --rm -p 8000:8000 -v $(pwd):/app internet-monitor
```

![Internet Monitor Dashboard](https://img.shields.io/badge/Status-Production%20Ready-green)
![Container](https://img.shields.io/badge/Container-Podman%2FDocker-blue)
![Python](https://img.shields.io/badge/Python-3.12-blue)
![License](https://img.shields.io/badge/License-MIT-green)

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

- **📍 Detaillierter Verlauf**: Minutengenaue Aufzeichnung aller Connectivity-Tests
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

```sql
CREATE TABLE status (
    ts INTEGER PRIMARY KEY,  -- Unix-Timestamp (Sekunden seit 1970)
    up INTEGER              -- 1=online, 0=offline
);
```

### 🔗 API-Endpunkte

- `GET /` - Responsive Web-Dashboard
- `GET /data` - JSON-API mit Roh- und Aggregationsdaten

### � Monitoring-Algorithmus

1. **HTTP-Test**: GET-Request an konfigurierte URL
2. **Timeout-Handling**: 5 Sekunden maximale Wartezeit
3. **Bewertung**: HTTP 2xx = Online | Timeout/Error = Offline
4. **Speicherung**: Timestamp + Status in SQLite
5. **Retention**: Automatisches Cleanup alter Daten

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
          CASE up WHEN 1 THEN 'Online' ELSE 'Offline' END as status 
   FROM status ORDER BY ts;" \
  -header -csv > connectivity_report.csv

# Statistiken abrufen
podman exec monitor-primary sqlite3 /app/data.db \
  "SELECT 
     COUNT(*) as total_checks,
     SUM(up) as successful_checks,
     ROUND(SUM(up) * 100.0 / COUNT(*), 2) as uptime_percentage
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
