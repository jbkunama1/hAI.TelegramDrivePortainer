# hAI.TelegramDrivePortainer

🚀 **Telegram-Drive als Docker Container** – Dein unbegrenzter Telegram-Cloud-Speicher im Portainer-Stack.

Basiert auf [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive) – gebaut als Headless-Container mit noVNC Web-Zugriff.

## 📋 Features

- ✅ **Unbegrenzter Cloud-Speicher** über Telegram-API
- ✅ **VNC-Access** – Browser-basiertes Web-Interface (noVNC)
- ✅ **Direkter VNC-Zugriff** für Desktop-Clients
- ✅ **REST-API exponiert** – Port 8550 via socat-Proxy (App bleibt loopback-intern)
- ✅ **Automatische Builds** via GitHub Actions (GHCR-Cache, schnelle Rebuilds)
- ✅ **GHCR Registry** – `ghcr.io/jbkunama1/hai.telegramdriveportainer`
- ✅ **Portainer-ready** – Ein-Klick-Deployment als Stack
- ✅ **Persistente Volumes** – Config, Keyring & Downloads bleiben erhalten
- ✅ **DBus + GNOME Keyring** – Secure Storage und Tray-Support funktionieren
- ✅ **Healthchecks** – Automatische Überwachung

## 🚀 Quick Start (Portainer)

### 1. Stack anlegen

1. **Portainer UI** öffnen → **Stacks** → **Add stack**
2. **Web Editor** wählen
3. Inhalt von `docker-compose.yml` einfügen

### 2. Passwort setzen (wichtig!)

**Nicht** im Editor hardcodieren. Stattdessen im Portainer-Stack-Editor **unter dem Textfeld** bei **Environment variables** eintragen:

```
VNC_PASSWORD=dein-sicheres-passwort
```

> ⚠️ UI-Variablen greifen nur, weil das Compose `${VNC_PASSWORD:-telegram123}` interpoliert. Hart codierte Werte im Compose würden die UI-Variablen ignorieren.

### 3. Deployen

**Deploy the stack** klicken. Beim ersten Start prüft das Startscript, ob ein Custom-Passwort gesetzt ist, und loggt:

```
[start] Custom VNC password is set (from VNC_PASSWORD env).
```

oder als Warnung:

```
[start] WARNING: Using DEFAULT VNC password! Set VNC_PASSWORD in Portainer.
```

### 4. Zugriff

- **Web-Interface (noVNC)**: `http://<dein-server>:6080` → Connect → dein VNC-Passwort
- **VNC-Client**: `<dein-server>:5900`

### 5. Telegram-Login

Beim ersten Start der App:

1. Auf [my.telegram.org](https://my.telegram.org) einloggen
2. **API development tools** → neue App erstellen
3. `api_id` und `api_hash` in der App eingeben

## 🔌 REST-API nutzen (Port 8550)

Die App bringt eine lokale REST-API mit (Dateien, Ordner, Bulk-Aktionen, Storage-Stats, Thumbnails, Media-Metadaten) – ideal für LLM-/Agent-Integration.

**Wichtig**: Die App bindet die API bewusst nur auf `127.0.0.1`. Dieser Container exponiert sie kontrolliert per socat-Proxy: extern `8550` → intern `8560` → App `127.0.0.1:8550`. Ein direktes Mapping `8550:8550` würde **nicht** funktionieren.

### API aktivieren

1. App über noVNC öffnen → **Settings** → **API Server**
2. **Enable API Server** aktivieren (Default: aus)
3. **API-Key generieren** (wird nur einmal angezeigt!)

### API aufrufen

```bash
curl -H "X-API-Key: DEIN_API_KEY" \
  http://<dein-server>:8550/api/v1/files
```

Volle Endpunkt-Doku: [REST_API_Documentation.md](https://github.com/caamer20/Telegram-Drive/blob/main/REST_API_Documentation.md) im Original-Repo.

> 💡 Die App hat zusätzlich **WebDAV** (Default-Port 8551) und einen **Media-Server** (14201) – beide ebenfalls loopback-only und per UI aktivierbar. Bei Bedarf dasselbe socat-Muster anwendbar.

## ⚙️ Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `VNC_PASSWORD` | `telegram123` | VNC-Zugangspasswort – **unbedingt ändern!** |
| `TZ` | `Europe/Berlin` | Zeitzone |

### Ports

| Port (extern) | Intern | Beschreibung |
|---------------|--------|--------------|
| `6080` | 6080 | noVNC Web-Interface (Browser) |
| `5900` | 5900 | VNC-Server (Desktop-Clients) |
| `8550` | 8560 | REST-API (socat → App-Loopback 8550) |

### Volumes

| Volume | Pfad im Container | Beschreibung |
|--------|-------------------|--------------|
| `telegram-drive-data` | `/root/.config` | App-Config, Telegram-Session, API-Settings |
| `telegram-drive-keyrings` | `/root/.local/share/keyrings` | GNOME Keyring (Secure Storage) |
| `telegram-drive-downloads` | `/root/Downloads` | Heruntergeladene Dateien |

## 🔑 Passwort nachträglich ändern

1. In Portainer: Stack → **Editor** → Environment variables → `VNC_PASSWORD` ändern
2. **Update the stack** (Container wird neu erstellt)
3. **Keyring beachten**: Der GNOME-Keyring wurde mit dem alten Passwort als Master-Passwort angelegt. Nach einer Passwort-Änderung kann er nicht mehr entsperrt werden. Falls du ihn schon genutzt hast: Credentials vorher sichern. Sonst einfach das Volume `telegram-drive-keyrings` löschen – er wird mit dem neuen Passwort neu erstellt.

## 🔒 Sicherheit

- **VNC-Passwort**: Unbedingt über die Portainer-Env-Variablen setzen!
- **REST-API**: Nur mit API-Key abgesichert (`X-API-Key` Header) – Key geheim halten. Die App erlaubt CORS `any_origin`; Port nur im LAN/freundlichen Netz exposen.
- **Network Isolation**: Stack läuft im eigenen Bridge-Netzwerk
- **Security-Scan**: Trivy-Scan bei jedem Push (siehe Workflow)
- **no-new-privileges**: Container-Security-Flag aktiv
- **Kein TLS in noVNC/API**: Für externe Erreichbarkeit Reverse Proxy (z. B. Traefik/NPM) mit TLS davor setzen

## 🛠️ Troubleshooting

### Container-Logs ansehen

```bash
docker logs telegram-drive
```

### VNC-Verbindung schlägt fehl

- Ports 6080/5900 korrekt gemappt? Firewall: `ufw allow 6080/tcp`
- Passwort stimmt nicht? → Prüfe im Log, ob `Custom VNC password is set` erscheint. Wenn `WARNING: Using DEFAULT` steht, wurde die UI-Variable nicht übernommen (Stack updaten!).

### REST-API nicht erreichbar

- In der App aktiviert? (Settings → API Server → Enable)
- API-Key im Header mitgeschickt?
- Im Log muss stehen: `[start] REST-API proxy listening on 0.0.0.0:8560 -> 127.0.0.1:8550`
- Test von außen: `curl -v http://<server>:8550/api/v1/files` (ohne Key → 401 ist ein gutes Zeichen)

### Harmlos im Log (kein Fehler)

- `Failed to read: session.*` (Fluxbox-Erststart)
- `Gdk-CRITICAL: gdk_window_thaw_toplevel_updates` (GTK unter Xvfb)
- `No SSL/TLS support` (websockify ohne Zertifikat – intern ok)
- `listen6: bind: Address already in use` (IPv6 in Docker)

## 📦 Build-Status

![Build Status](https://github.com/jbkunama1/hAI.TelegramDrivePortainer/actions/workflows/build-and-push.yml/badge.svg)

## 📝 Lizenz & Credits

- **Original-Projekt**: [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive)
- **Tauri Framework**: [tauri.app](https://tauri.app)
- **noVNC**: [novnc.com](https://novnc.com)
- **Dieses Docker-Setup**: MIT License

---

**Viel Spaß mit deinem Telegram-Cloud-Speicher!** 🚀
