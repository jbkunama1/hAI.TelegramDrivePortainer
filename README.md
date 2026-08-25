# hAI.TelegramDrivePortainer

🚀 **Telegram-Drive als Docker Container** – Dein unbegrenzter Telegram-Cloud-Speicher im Portainer-Stack.

Basiert auf [caamer20/Telegram-Drive](https://github.com/caamer20/Telegram-Drive) – gebaut als Headless-Container mit noVNC Web-Zugriff.

## 📋 Features

- ✅ **Unbegrenzter Cloud-Speicher** über Telegram-API
- ✅ **VNC-Access** – Browser-basiertes Web-Interface (noVNC, eigene Landing-Page mit Autoconnect)
- ✅ **REST-API per ENV konfigurierbar** – `TG_API_KEY` setzen, fertig (kein UI-Klick nötig)
- ✅ **highfishNetwork** – läuft in deinem bestehenden Netz, intern erreichbar als `telegram-drive`
- ✅ **Automatische Builds** via GitHub Actions (GHCR-Cache, schnelle Rebuilds)
- ✅ **Persistente Volumes** – Config, App-Daten (Session!), Keyring & Downloads
- ✅ **DBus + GNOME Keyring** – Secure Storage und Tray-Support funktionieren
- ✅ **Healthchecks** – Automatische Überwachung

## 🚀 Quick Start (Portainer)

### 1. Stack anlegen

1. **Portainer UI** öffnen → **Stacks** → **Add stack**
2. **Web Editor** wählen
3. Inhalt von `docker-compose.yml` einfügen

### 2. Environment variables setzen (unter dem Editor)

```
VNC_PASSWORD=dein-sicheres-passwort
TG_API_KEY=dein-langer-api-key
```

> ⚠️ UI-Variablen greifen nur über die `${...}`-Interpolation im Compose.
> `TG_API_KEY` ist optional – ohne ihn bleibt die API aus und lässt sich per UI aktivieren.

### 3. Deployen

**Deploy the stack**. Das Startscript loggt den Status:

```
[start] Custom VNC password is set (from VNC_PASSWORD env).
[start] REST-API auto-enabled (key from TG_API_KEY env, sha256 hash written).
[start] REST-API proxy listening on 0.0.0.0:8560 -> 127.0.0.1:8550
```

### 4. Zugriff

- **Web-Interface (noVNC)**: `http://<dein-server>:6080` → Landing-Page leitet automatisch weiter → VNC-Passwort
- **VNC-Client**: `<dein-server>:5900`

### 5. Telegram-Login

1. Auf [my.telegram.org](https://my.telegram.org) einloggen
2. **API development tools** → neue App erstellen
3. `api_id` und `api_hash` in der App eingeben

## 🔌 REST-API (Port 8550)

Endpunkte für Dateien, Ordner, Bulk-Aktionen, Storage-Stats, Thumbnails, Media-Metadaten – ideal für LLM-/Agent-Integration.

### Aktivierung per ENV (empfohlen)

`TG_API_KEY` in den Portainer Environment Variables setzen. Das Startscript schreibt daraus deklarativ die App-Config (`api_settings.json` mit SHA-256-Hash des Keys, `enabled: true`, Port 8550). **Hinweis**: Bei gesetztem `TG_API_KEY` werden UI-Änderungen an den API-Settings beim Neustart überschrieben.

Alternativ ohne ENV: App → **Settings** → **API Server** → Enable + Key generieren.

### Aufruf

```bash
curl -H "X-API-Key: DEIN_KEY" http://<dein-server>:8550/api/v1/files
```

**Intern (Container im highfishNetwork)** – kein Port-Mapping nötig:

```bash
curl -H "X-API-Key: DEIN_KEY" http://telegram-drive:8560/api/v1/files
```

Volle Endpunkt-Doku: [REST_API_Documentation.md](https://github.com/caamer20/Telegram-Drive/blob/main/REST_API_Documentation.md) im Original-Repo.

> 💡 Die App bindet die API bewusst nur auf `127.0.0.1` – dieser Container exponiert sie kontrolliert per socat (`8560` intern → extern `8550`). Ein Mapping `8550:8550` würde nicht funktionieren.
> 💡 Zusätzlich vorhanden: **WebDAV** (Default 8551) und **Media-Server** (14201), beide loopback-only, per UI aktivierbar.

## ⚙️ Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `VNC_PASSWORD` | `telegram123` | VNC-Passwort – **unbedingt ändern!** |
| `TG_API_KEY` | _(leer)_ | API-Key; aktiviert die REST-API automatisch |
| `TZ` | `Europe/Berlin` | Zeitzone |

### Ports

| Extern | Intern | Beschreibung |
|--------|--------|--------------|
| `6080` | 6080 | noVNC Web-Interface |
| `5900` | 5900 | VNC-Server |
| `8550` | 8560 | REST-API (socat → App-Loopback 8550) |

### Volumes

| Volume | Pfad im Container | Inhalt |
|--------|-------------------|--------|
| `telegram-drive-data` | `/root/.config` | App-Config |
| `telegram-drive-appdata` | `/root/.local/share/com.cameronamer.telegramdrive` | App-Daten: `api_settings.json`, Session-DB |
| `telegram-drive-keyrings` | `/root/.local/share/keyrings` | GNOME Keyring (Secure Storage) |
| `telegram-drive-downloads` | `/root/Downloads` | Downloads |

### Netzwerk

Externes Netz `highfishNetwork` (muss existieren: `docker network create highfishNetwork`). Andere Container darin erreichen den Stack per DNS als `telegram-drive` (API: Port `8560`, noVNC: `6080`).

## 🔑 Passwort nachträglich ändern

1. Portainer: Stack → **Editor** → Environment variables → ändern
2. **Update the stack**
3. **Keyring beachten**: Er wurde mit dem alten `VNC_PASSWORD` als Master-Passwort angelegt. Nach Änderung: Volume `telegram-drive-keyrings` löschen → wird neu erstellt.

## 🔒 Sicherheit

- **VNC-Passwort + API-Key** nur über Portainer-Env setzen (beide sind im Stack-Editor sichtbar → Portainer-Zugriff entsprechend absichern)
- **REST-API**: `X-API-Key`-Pflicht, aber CORS `any_origin` → nur im LAN/vertrauenswürdigen Netz exposen
- **Kein TLS** in noVNC/API → bei externer Erreichbarkeit Reverse Proxy mit TLS davor
- **no-new-privileges**, eigenes externes Netz, Trivy-Scan bei jedem Push

## 🛠️ Troubleshooting

### VNC-Passwort greift nicht

Im Log muss `Custom VNC password is set` stehen. Bei `WARNING: Using DEFAULT` wurde die UI-Variable nicht übernommen → Stack mit Env-Eintrag updaten.

### REST-API nicht erreichbar

- `TG_API_KEY` gesetzt? Log: `REST-API auto-enabled ...`
- Proxy läuft? Log: `REST-API proxy listening on 0.0.0.0:8560`
- Test: `curl -v http://<server>:8550/api/v1/files` → **401 ohne Key ist ein gutes Zeichen**
- Interner Test aus anderem Container: `curl -v http://telegram-drive:8560/api/v1/files`

### Harmlos im Log (kein Fehler)

- `Failed to read: session.*` (Fluxbox-Erststart)
- `Gdk-CRITICAL: gdk_window_thaw_toplevel_updates` (GTK unter Xvfb)
- `No SSL/TLS support` (websockify – intern ok)
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
