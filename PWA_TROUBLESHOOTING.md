# PWA Installation Troubleshooting

## Hauptprobleme bei localhost Docker

### 1. 🔴 HTTPS Requirement
PWAs benötigen HTTPS, **außer** bei exakt `localhost` (nicht `127.0.0.1`).

**Lösung:**
```bash
# Statt Docker mit Port-Mapping
docker run -p 8000:8000 your-app

# Zugriff über:
http://localhost:8000  ✅ (PWA funktioniert)
# NICHT über:
http://127.0.0.1:8000  ❌ (PWA funktioniert nicht)
```

### 2. 🔧 Browser Developer Tools nutzen

Öffnen Sie `http://localhost:8000` und prüfen Sie:

**Console (F12 → Console):**
```
🔍 PWA Debug Info:
✅ SW registriert mit Scope: /
✅ Manifest geladen: {name: "Internet-Verbindungsmonitor", ...}
📱 PWA Install Prompt verfügbar
```

**Application Tab (F12 → Application):**
- **Manifest**: Sollte grün ✅ sein
- **Service Workers**: Status "Activated and running"

### 3. 🚀 Installation testen

**Chrome/Edge:**
1. Adressleiste: Install-Icon 📱 oder
2. Menü → "App installieren" oder  
3. Automatischer "App installieren" Button (20 Sek)

**Firefox:** 
- Menü → "Diese Seite installieren"

**Mobile:**
- Browser-Menü → "Zum Startbildschirm hinzufügen"

### 4. 🐛 Debugging

```bash
# Container starten
docker build -t internet-monitor .
docker run -p 8000:8000 internet-monitor

# Dann Browser öffnen mit:
http://localhost:8000
```

**Wenn PWA nicht installierbar:**

1. **F12 → Console** → Suche nach Fehlern
2. **F12 → Application → Manifest** → Prüfe Errors
3. **F12 → Network** → Prüfe 404-Fehler bei `/manifest.json` oder `/sw.js`

### 5. ⚠️ Bekannte Einschränkungen

- **127.0.0.1**: PWA funktioniert nicht (HTTPS required)
- **IP-Adressen**: PWA funktioniert nicht (HTTPS required)  
- **HTTP**: Nur `localhost` ist erlaubt
- **Incognito/Private**: Teilweise eingeschränkt

### 6. 🔧 Produktionsumgebung

Für echte Produktionsumgebung HTTPS verwenden:

```bash
# Mit nginx + Let's Encrypt
# Oder CloudFlare
# Oder andere HTTPS-Lösung
```

## Testen Sie es:

1. `docker build -t internet-monitor .`
2. `docker run -p 8000:8000 internet-monitor`  
3. Browser: `http://localhost:8000`
4. F12 → Console → Suche nach "PWA Debug Info"
5. Nach ~5 Sekunden sollte "📱 App installieren" Button erscheinen
