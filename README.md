# hAI.TelegramDrivePortainer

🚀 **Telegram-Drive als Docker Container** – Dein unbegrenzter Telegram-Cloud-Speicher im Portainer-Stack.

Basiert auf [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive) – gebaut als Headless-Container mit noVNC Web-Zugriff.

## 📋 Features

- ✅ **Unbegrenzter Cloud-Speicher** über Telegram-API
- ✅ **VNC-Access** – Browser-basiertes Web-Interface (noVNC)
- ✅ **Direkter VNC-Zugriff** für Desktop-Clients
- ✅ **Automatische Builds** via GitHub Actions
- ✅ **GHCR Registry** – `ghcr.io/jbkunama1/hai.telegramdriveportainer`
- ✅ **Portainer-ready** – Ein-Klick-Deployment als Stack
- ✅ **Persistente Volumes** – Config & Downloads bleiben erhalten
- ✅ **Healthchecks** – Automatische Überwachung

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────┐
│  GitHub Actions (CI/CD)                             │
│  - Build auf Push/Tag                               │
│  - Push nach GHCR                                   │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  GHCR: ghcr.io/jbkunama1/hai.telegramdriveportainer │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Portainer Stack                                    │
│  - docker-compose.yml                               │
│  - VNC-Port: 5900                                   │
│  - Web-Port: 6080 (noVNC)                           │
└─────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. In Portainer deployen

1. **Portainer UI** öffnen
2. **Stacks** → **Add stack**
3. **Web Editor** wählen
4. Inhalt von `docker-compose.yml` einfügen
5. **Deploy the stack**

### 2. Zugriff

- **Web-Interface (noVNC)**: `http://<dein-server>:6080`
  - VNC-Passwort: `telegram123` (in `docker-compose.yml` anpassen!)
- **VNC-Client**: `<dein-server>:5900`

### 3. Telegram-Login

Beim ersten Start der App:
1. Auf [my.telegram.org](https://my.telegram.org) einloggen
2. **API development tools** → neue App erstellen
3. `api_id` und `api_hash` in der App eingeben

## ⚙️ Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `VNC_PASSWORD` | `telegram123` | VNC-Zugangspasswort |
| `TZ` | `Europe/Berlin` | Zeitzone |

### Ports

| Port | Protokoll | Beschreibung |
|------|-----------|--------------|
| `6080` | TCP | noVNC Web-Interface (Browser) |
| `5900` | TCP | VNC-Server (Desktop-Clients) |

### Volumes

| Volume | Pfad im Container | Beschreibung |
|--------|-------------------|--------------|
| `telegram-drive-data` | `/root/.config/telegram-drive` | App-Config & Session |
| `telegram-drive-downloads` | `/root/Downloads` | Heruntergeladene Dateien |

## 🔒 Sicherheit

- **VNC-Passwort**: Unbedingt in `docker-compose.yml` ändern!
- **Network Isolation**: Stack läuft im eigenen Bridge-Netzwerk
- **Security-Scan**: Trivy-Scan bei jedem Push (siehe Workflow)
- **no-new-privileges**: Container-Security-Flag aktiv

## 🛠️ Troubleshooting

### Container startet nicht

```bash
# Logs ansehen
docker logs telegram-drive

# In Container shellen
docker exec -it telegram-drive bash
```

### VNC-Verbindung schlägt fehl

- Prüfe, ob Ports 6080/5900 korrekt gemappt sind
- Firewall-Regeln prüfen: `ufw allow 6080/tcp` und `ufw allow 5900/tcp`

### Telegram-Login funktioniert nicht

- API-ID und API-Hash von [my.telegram.org](https://my.telegram.org) bereithalten
- Session wird im Volume `telegram-drive-data` persistiert

## 📦 Build-Status

![Build Status](https://github.com/jbkunama1/hAI.TelegramDrivePortainer/actions/workflows/build-and-push.yml/badge.svg)

## 📝 Lizenz

- **Telegram-Drive Original**: [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive)
- **Dieses Docker-Setup**: MIT License

## 🙏 Credits

- **Original-Projekt**: [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive)
- **Tauri Framework**: [tauri.app](https://tauri.app)
- **noVNC**: [novnc.com](https://novnc.com)

---

**Viel Spaß mit deinem Telegram-Cloud-Speicher!** 🚀
