# hAI.TelegramDrivePortainer

🚀 **Telegram-Drive als Docker Container** – Dein unbegrenzter Telegram-Cloud-Speicher im Portainer-Stack.

Basiert auf [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive) – gebaut als Headless-Container mit noVNC Web-Zugriff.

## 📋 Features

- ✅ **Unbegrenzter Cloud-Speicher** über Telegram-API
- ✅ **VNC-Access** – Browser-basiertes Web-Interface (noVNC)
- ✅ **Direkter VNC-Zugriff** für Desktop-Clients
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

## ⚙️ Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `VNC_PASSWORD` | `telegram123` | VNC-Zugangspasswort – **unbedingt ändern!** |
| `TZ` | `Europe/Berlin` | Zeitzone |

### Ports

| Port | Protokoll | Beschreibung |
|------|-----------|--------------|
| `6080` | TCP | noVNC Web-Interface (Browser) |
| `5900` | TCP | VNC-Server (Desktop-Clients) |

### Volumes

| Volume | Pfad im Container | Beschreibung |
|--------|-------------------|--------------|
| `telegram-drive-data` | `/root/.config` | App-Config & Telegram-Session |
| `telegram-drive-keyrings` | `/root/.local/share/keyrings` | GNOME Keyring (Secure Storage) |
| `telegram-drive-downloads` | `/root/Downloads` | Heruntergeladene Dateien |

## 🔑 Passwort nachträglich ändern

1. In Portainer: Stack → **Editor** → Environment variables → `VNC_PASSWORD` ändern
2. **Update the stack** (Container wird neu erstellt)
3. **Keyring beachten**: Der GNOME-Keyring wurde mit dem alten Passwort als Master-Passwort angelegt. Nach einer Passwort-Änderung kann er nicht mehr entsperrt werden. Falls du ihn schon genutzt hast: Credentials vorher sichern. Sonst einfach das Volume `telegram-drive-keyrings` löschen – er wird mit dem neuen Passwort neu erstellt.

## 🔒 Sicherheit

- **VNC-Passwort**: Unbedingt über die Portainer-Env-Variablen setzen!
- **Network Isolation**: Stack läuft im eigenen Bridge-Netzwerk
- **Security-Scan**: Trivy-Scan bei jedem Push (siehe Workflow)
- **no-new-privileges**: Container-Security-Flag aktiv
- **Kein TLS in noVNC**: Für externe Erreichbarkeit Reverse Proxy (z. B. Traefik/NPM) mit TLS davor setzen

## 🛠️ Troubleshooting

### Container-Logs ansehen

```bash
docker logs telegram-drive
```

### VNC-Verbindung schlägt fehl

- Ports 6080/5900 korrekt gemappt? Firewall: `ufw allow 6080/tcp`
- Passwort stimmt nicht? → Prüfe im Log, ob `Custom VNC password is set` erscheint. Wenn `WARNING: Using DEFAULT` steht, wurde die UI-Variable nicht übernommen (Stack updaten!).

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
