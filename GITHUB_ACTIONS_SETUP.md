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

## 🚀 Workflow-Features

Die GitHub Action wird automatisch ausgelöst bei:

- **Push zu main branch**: Erstellt `latest` Tag
- **Git Tags** (z.B. `v1.0.0`): Erstellt entsprechende Docker Tags
- **Pull Requests**: Testet den Build ohne zu veröffentlichen
- **Manueller Trigger**: Über GitHub UI ausführbar

### 🏷️ Tag-Schema

| Git Event | Docker Tags |
|-----------|-------------|
| `push main` | `latest` |
| `git tag v1.2.3` | `v1.2.3`, `1.2`, `1` |
| `pull request` | Nur Build-Test |

### 🌐 Multi-Platform Support

Der Workflow erstellt Images für:
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
