# 🚀 Release und Versionierung

## Übersicht

Das Internet Monitor Projekt verwendet ein vollautomatisches Release-System basierend auf **Semantic Versioning** (SemVer). Bei jedem Push zur `main`-Branch wird automatisch eine neue **Patch-Version** erstellt und veröffentlicht.

## 📋 Semantic Versioning Schema

Format: `MAJOR.MINOR.PATCH` (z.B. `v2.1.3`)

- **MAJOR** (v2.0.0): Breaking Changes, nicht abwärtskompatible Änderungen
- **MINOR** (v1.1.0): Neue Features, abwärtskompatible Funktionalitäten
- **PATCH** (v1.0.1): Bug-Fixes, abwärtskompatible Verbesserungen

## 🎯 Release-Strategien

### 1. Automatischer Release (Standard)

**Wann:** Bei jedem Push zur `main`-Branch
**Version-Type:** Patch (z.B. v1.0.0 → v1.0.1)

```bash
# Normale Entwicklung
git add .
git commit -m "fix: Verbindungsstatistik korrigiert"
git push origin main

# ✅ Automatisch erstellt: v1.0.1
```

### 2. Manueller Release mit Script

**Interaktives Script für alle Version-Types**

```bash
./release.sh
```

Das Script führt Sie durch:
1. Prüfung des Git-Status
2. Anzeige der aktuellen Version
3. Auswahl des Version-Types
4. Automatischer Start des Release-Workflows

### 3. Manueller Release über GitHub

**Für spezielle Releases oder CI/CD-Tests**

1. Gehe zu **Actions** → **Automatic Release and Version Tagging**
2. Klicke **Run workflow**
3. Wähle Branch: `main`
4. Wähle Version Type: `patch`, `minor`, oder `major`
5. Klicke **Run workflow**

## 📦 Was passiert bei einem Release?

### 1. Version & Tag Creation
- Neue Semantic Version berechnen
- Git Tag erstellen (z.B. `v1.2.3`)
- Tag zu GitHub pushen

### 2. GitHub Release
- GitHub Release mit Changelog erstellen
- Automatische Beschreibung basierend auf Commits
- Release in GitHub UI sichtbar

### 3. Docker Images
- Multi-Platform Build (AMD64 + ARM64)
- Multiple Tags erstellen:
  - `latest` (immer neueste Version)
  - `1.2.3` (exakte Version)
  - `1.2` (Major.Minor)
  - `1` (nur Major)
- Push zu Docker Hub

### 4. Dokumentation
- Docker Hub Beschreibung aktualisieren
- Release-Notes generieren

## 🏷️ Tag-Beispiele

| Commit | Auto-Tag | Manual Tags verfügbar |
|--------|----------|----------------------|
| Bug-Fix | v1.0.1 | patch: v1.0.1 |
| Feature | v1.0.1 | minor: v1.1.0 |
| Breaking | v1.0.1 | major: v2.0.0 |

## 🐳 Docker Tag-Schema

Bei Release v1.2.3 werden folgende Docker Images erstellt:

```bash
syntaxsorcerer7/internet-monitor:latest
syntaxsorcerer7/internet-monitor:1.2.3
syntaxsorcerer7/internet-monitor:1.2
syntaxsorcerer7/internet-monitor:1
```

**Verwendung:**
```bash
# Neueste Version (empfohlen für Entwicklung)
docker pull syntaxsorcerer7/internet-monitor:latest

# Spezifische Version (empfohlen für Produktion)
docker pull syntaxsorcerer7/internet-monitor:1.2.3

# Major.Minor (automatische Patch-Updates)
docker pull syntaxsorcerer7/internet-monitor:1.2
```

## 🔄 Entwicklungsworkflow

### Feature Development
```bash
# Feature Branch erstellen
git checkout -b feature/neue-statistik

# Entwicklung...
git add .
git commit -m "feat: neue Statistik-Ansicht hinzugefügt"

# Pull Request erstellen
git push origin feature/neue-statistik

# Nach Merge zur main → automatischer Patch-Release
```

### Bug Fixes
```bash
# Hotfix Branch erstellen
git checkout -b hotfix/connection-bug

# Fix implementieren
git add .
git commit -m "fix: Verbindungsfehler bei timeout behoben"

# Pull Request und Merge → automatischer Patch-Release
```

### Major/Minor Releases
```bash
# Für größere Features oder Breaking Changes
git add .
git commit -m "feat!: neue API-Version implementiert (BREAKING CHANGE)"

# Manueller Major-Release
./release.sh
# Wähle: 3) Major Release
```

## 📊 Release Monitoring

### GitHub
- **Releases**: [GitHub Releases](https://github.com/SyntaxSorcerer7/internet-check/releases)
- **Actions**: [GitHub Actions](https://github.com/SyntaxSorcerer7/internet-check/actions)

### Docker Hub
- **Repository**: [syntaxsorcerer7/internet-monitor](https://hub.docker.com/r/syntaxsorcerer7/internet-monitor)
- **Tags**: Alle verfügbaren Versionen

### Lokal prüfen
```bash
# Lokale Tags anzeigen
git tag -l

# Remote Tags anzeigen
git ls-remote --tags origin

# Neueste Version abrufen
git describe --tags --abbrev=0
```

## 🚨 Troubleshooting

### Release schlägt fehl
1. Prüfe GitHub Actions Logs
2. Verifiziere Docker Hub Credentials
3. Prüfe auf Git-Konflikte

### Version existiert bereits
```bash
# Lokale Tags prüfen
git tag -l

# Problematischen Tag löschen (nur wenn notwendig)
git tag -d v1.2.3
git push --delete origin v1.2.3
```

### Rollback
```bash
# Zu vorheriger Version zurück
docker pull syntaxsorcerer7/internet-monitor:1.2.2

# Oder spezifischen Tag verwenden
git checkout v1.2.2
./build-and-run.sh
```

## 📝 Best Practices

### Commit Messages
- `feat:` für neue Features → Minor-Release empfohlen
- `fix:` für Bug-Fixes → Patch-Release automatisch
- `docs:` für Dokumentation → Patch-Release
- `feat!:` oder `BREAKING CHANGE:` → Major-Release empfohlen

### Release Timing
- **Patch**: Jederzeit (automatisch)
- **Minor**: Nach Feature-Fertigstellung (manuell)
- **Major**: Nur bei Breaking Changes (manuell)

### Production Deployment
- Verwende immer spezifische Versions-Tags
- Teste neue Releases erst in Staging
- Dokumentiere Breaking Changes ausführlich
