# GitHub Actions Setup für Docker Hub Deployment

## Erforderliche GitHub Secrets

Um die automatische Container-Erstellung und -Veröffentlichung zu aktivieren, müssen folgende Secrets in den GitHub Repository-Einstellungen konfiguriert werden:

### 🔐 Secrets konfigurieren

1. Gehe zu deinem GitHub Repository
2. Klicke auf **Settings** → **Secrets and variables** → **Actions**
3. Füge folgende Secrets hinzu:

| Secret Name | Beschreibung | Wert |
|-------------|--------------|------|
| `DOCKERHUB_USERNAME` | Dein Docker Hub Benutzername | `syntaxsorcerer7` |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token | `[GENERIERTER_TOKEN]` |

### 🔑 Docker Hub Access Token erstellen

1. Logge dich in [Docker Hub](https://hub.docker.com) ein
2. Gehe zu **Account Settings** → **Security**
3. Klicke auf **New Access Token**
4. Gib einen Namen ein (z.B. "GitHub Actions")
5. Wähle **Read, Write, Delete** Permissions
6. Kopiere den generierten Token
7. Füge ihn als `DOCKERHUB_TOKEN` Secret in GitHub hinzu

## 🚀 Automatisches Release-System

Das Projekt verwendet ein vollautomatisches Release-System mit zwei GitHub Actions:

### 📦 Release Workflow (`release.yml`)

**Trigger:**

- **Automatisch**: Bei jedem Push zur `main`-Branch
- **Manuell**: Über GitHub UI mit wählbarem Version-Type

**Features:**

- ✅ Automatische Semantic Versioning (major.minor.patch)
- ✅ Git Tags mit Version erstellen
- ✅ GitHub Releases mit Changelog
- ✅ Docker Images mit Version-Tags
- ✅ Multi-Platform Docker Builds (AMD64/ARM64)

### 🧪 Build & Test Workflow (`docker-build-push.yml`)

**Trigger:**

- **Pull Requests**: Nur Build-Test ohne Publishing
- **Manuell**: Mit Option zum Pushen nach Docker Hub

### 🏷️ Version & Tag Schema

| Trigger | Git Tag | Docker Tags | GitHub Release |
|---------|---------|-------------|----------------|
| Push main | v1.0.1 | latest, 1.0.1, 1.0, 1 | ✅ Release v1.0.1 |
| Manual patch | v1.0.2 | latest, 1.0.2, 1.0, 1 | ✅ Release v1.0.2 |
| Manual minor | v1.1.0 | latest, 1.1.0, 1.1, 1 | ✅ Release v1.1.0 |
| Manual major | v2.0.0 | latest, 2.0.0, 2.0, 2 | ✅ Release v2.0.0 |

### 🎯 Release erstellen

#### Option 1: Automatisch (empfohlen)

```bash
# Einfach zur main branch pushen
git add .
git commit -m "feat: neue Feature implementiert"
git push origin main

# → Automatisch wird Patch-Version erstellt (z.B. v1.0.1)
```

#### Option 2: Manuell mit Script

```bash
# Interaktives Release-Script verwenden
./release.sh

# Wähle Version-Type:
# 1) Patch (Bug-Fix)
# 2) Minor (Feature)  
# 3) Major (Breaking Change)
```

#### Option 3: Manuell über GitHub UI

1. Gehe zu **Actions** → **Automatic Release and Version Tagging**
2. Klicke **Run workflow**
3. Wähle Version Type (patch/minor/major)
4. Klicke **Run workflow**

### 🌐 Multi-Platform Support

Alle Docker Images werden für folgende Plattformen erstellt:

- **linux/amd64** (Intel/AMD x64)
- **linux/arm64** (ARM64, Apple Silicon, Raspberry Pi)

## 📋 Verwendung

Nach dem Setup werden Container automatisch erstellt und sind verfügbar unter:

```bash
# Latest Version
docker pull syntaxsorcerer7/internet-monitor:latest

# Spezifische Version
docker pull syntaxsorcerer7/internet-monitor:v1.0.0
```

## 🔄 Workflow-Status

Der Build-Status ist sichtbar:
- Im GitHub Repository unter **Actions** Tab
- Als Badge in der README (optional)
- In den Commit-Checks

## 🐛 Troubleshooting

### Build schlägt fehl
1. Prüfe die Logs unter **Actions** → **failed workflow**
2. Stelle sicher, dass alle Secrets korrekt gesetzt sind
3. Verifiziere Docker Hub Permissions

### Token abgelaufen
1. Erstelle neuen Access Token in Docker Hub
2. Aktualisiere `DOCKERHUB_TOKEN` Secret in GitHub

### Multi-Platform Build Probleme
1. Prüfe ob alle Dependencies ARM64-kompatibel sind
2. Logs der spezifischen Plattform in Actions analysieren
