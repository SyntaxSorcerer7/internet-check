# Internet-Verbindungsmonitor 🌐

![Docker Pulls](https://img.shields.io/docker/pulls/syntaxsorcerer7/internet-monitor)
![Docker Image Size](https://img.shields.io/docker/image-size/syntaxsorcerer7/internet-monitor)
![Docker Stars](https://img.shields.io/docker/stars/syntaxsorcerer7/internet-monitor)

Ein containerisiertes Internet-Monitoring-Tool, das die Verfügbarkeit Ihrer Internetverbindung kontinuierlich überwacht und in einer übersichtlichen Web-Oberfläche mit professionellen Diagrammen visualisiert.

## 🚀 Schnellstart

```bash
# Container starten
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  syntaxsorcerer7/internet-monitor

# Web-Interface öffnen
open http://localhost:8000
```

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
- **Multi-Platform**: Unterstützt AMD64 und ARM64 (Raspberry Pi, Apple Silicon)
- **Hochperformant**: Minimaler Ressourcenverbrauch durch Alpine Linux

## ⚙️ Konfiguration

Alle Einstellungen erfolgen über Umgebungsvariablen:

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `CHECK_INTERVAL_SEC` | `20` | Intervall zwischen Connectivity-Tests (Sekunden) |
| `RETENTION_DAYS` | `60` | Aufbewahrungsdauer der Messdaten (Tage) |
| `TEST_URL` | `https://1.1.1.1` | Ziel-URL für Connectivity-Tests |
| `DB_PATH` | `data.db` | Pfad zur SQLite-Datenbankdatei |

## 🛠️ Verwendung

### Standard-Konfiguration
```bash
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  syntaxsorcerer7/internet-monitor
```

### Erweiterte Konfiguration
```bash
# Hochfrequentes Monitoring (alle 10 Sekunden)
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  -e CHECK_INTERVAL_SEC=10 \
  -e RETENTION_DAYS=90 \
  syntaxsorcerer7/internet-monitor

# Monitoring verschiedener Ziele
docker run -d --name monitor-google -p 8001:8000 \
  -e TEST_URL=https://google.com \
  syntaxsorcerer7/internet-monitor

docker run -d --name monitor-github -p 8002:8000 \
  -e TEST_URL=https://github.com \
  syntaxsorcerer7/internet-monitor
```

### Persistente Daten
```bash
# Datenbank außerhalb des Containers speichern
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  -v $(pwd)/monitor-data:/app \
  syntaxsorcerer7/internet-monitor
```

### Docker Compose
```yaml
version: '3.8'
services:
  internet-monitor:
    image: syntaxsorcerer7/internet-monitor:latest
    container_name: internet-monitor
    ports:
      - "8000:8000"
    environment:
      - CHECK_INTERVAL_SEC=20
      - RETENTION_DAYS=60
      - TEST_URL=https://1.1.1.1
    volumes:
      - ./monitor-data:/app
    restart: unless-stopped
```

## 📊 SLA-Referenztabelle

| Verfügbarkeit | Ausfallzeit/Jahr | Ausfallzeit/Monat | Ausfallzeit/Tag | Bewertung |
|---------------|------------------|-------------------|-----------------|-----------|
| 99,99% | 52,6 Minuten | 4,4 Minuten | 8,6 Sekunden | 🟢 Exzellent |
| 99,9% | 8,77 Stunden | 43,8 Minuten | 1,44 Minuten | 🟢 Exzellent |
| 99,5% | 43,8 Stunden | 3,65 Stunden | 7,2 Minuten | 🟡 Gut |
| 99,0% | 87,7 Stunden | 7,31 Stunden | 14,4 Minuten | 🟡 Gut |
| 98,0% | 175 Stunden | 14,6 Stunden | 28,8 Minuten | 🔴 Problematisch |

## 💡 Anwendungsfälle

- **🏠 Heimnetzwerk**: Überwachung der DSL/Glasfaser-Verbindung
- **🏢 Büronetzwerke**: Dokumentation von Provider-Ausfällen
- **📋 SLA-Monitoring**: Nachweis der Verfügbarkeit für Verträge
- **🔧 Troubleshooting**: Root-Cause-Analyse bei Verbindungsproblemen
- **📈 Kapazitätsplanung**: Langzeit-Trendanalyse für Upgrades

## 🚨 Troubleshooting

### Container startet nicht
```bash
# Logs prüfen
docker logs internet-monitor

# Port-Konflikte checken
netstat -tulpn | grep :8000
lsof -i :8000
```

### Keine Daten sichtbar
- **Warten**: Mindestens 1-2 Minuten nach dem Start warten
- **Netzwerk**: Container-Netzwerkverbindung prüfen
- **URL**: TEST_URL-Erreichbarkeit validieren
- **Firewall**: Ausgehende HTTP-Verbindungen erlauben

### Performance-Optimierung
```bash
# Speicherverbrauch reduzieren
docker run -d -e RETENTION_DAYS=7 syntaxsorcerer7/internet-monitor

# Höhere Frequenz für kritische Systeme
docker run -d -e CHECK_INTERVAL_SEC=5 syntaxsorcerer7/internet-monitor

# Ressourcen-Limits setzen
docker run -d --memory=128m --cpus=0.5 syntaxsorcerer7/internet-monitor
```

## 🏗️ Architektur

- **Backend**: Python Flask mit SQLite-Datenbank
- **Frontend**: Responsive HTML mit Chart.js-Visualisierungen
- **Container**: Alpine Linux (Python 3.12) für minimalen Footprint
- **Monitoring**: HTTP-Requests mit 5s Timeout für zuverlässige Tests
- **Multi-Platform**: Unterstützt AMD64 und ARM64 Architekturen

## 🔗 Links

- **GitHub Repository**: [SyntaxSorcerer7/internet-check](https://github.com/SyntaxSorcerer7/internet-check)
- **Issues & Support**: [GitHub Issues](https://github.com/SyntaxSorcerer7/internet-check/issues)
- **Docker Hub**: [syntaxsorcerer7/internet-monitor](https://hub.docker.com/r/syntaxsorcerer7/internet-monitor)

## 📝 Lizenz

Dieses Projekt steht unter der **MIT-Lizenz**.

---

Made with ❤️ for reliable internet monitoring
