#!/bin/bash
set -e

# Passwort-Status loggen (ohne das Passwort selbst auszugeben)
if [ -n "$VNC_PASSWORD" ] && [ "$VNC_PASSWORD" != "telegram123" ]; then
  echo "[start] Custom VNC password is set (from VNC_PASSWORD env)."
else
  echo "[start] WARNING: Using DEFAULT VNC password! Set VNC_PASSWORD in Portainer."
fi

# VNC-Passwort setzen (x11vnc-eigenes Tool, kein vncpasswd noetig)
mkdir -p ~/.vnc
x11vnc -storepasswd "${VNC_PASSWORD:-telegram123}" ~/.vnc/passwd

# Xvfb starten (virtuelles Display)
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# DBus Session Bus starten (braucht die App fuer Tray-Icon + Secure Storage)
eval "$(dbus-launch --sh-syntax)"

# GNOME Keyring als Secret Service starten/entsperren
# (Platform secure storage; Passwort = VNC_PASSWORD, Keyring liegt im Volume)
echo -n "${VNC_PASSWORD:-telegram123}" | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null || true

# REST-API per ENV ein-/ausschalten (TG_API_KEY=true/false).
# Der API-Key selbst wird weiterhin in der App-UI generiert!
# Wir patchen per jq NUR das 'enabled'-Feld in api_settings.json -
# ein per UI gesetzter key_hash (und der Port) bleiben erhalten.
# Pfad: <app_data_dir>/api_settings.json (identifier: com.cameronamer.telegramdrive)
APP_DATA_DIR="/root/.local/share/com.cameronamer.telegramdrive"
SETTINGS_FILE="$APP_DATA_DIR/api_settings.json"

set_api_enabled() {
  local enabled="$1"
  mkdir -p "$APP_DATA_DIR"
  if [ -f "$SETTINGS_FILE" ] && jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
    # Bestehende Datei: nur enabled patchen, key_hash/port erhalten
    jq ".enabled = $enabled" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
      && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    # Neu anlegen (Key wird danach in der UI generiert)
    printf '{"enabled":%s,"port":8550,"key_hash":null}\n' "$enabled" > "$SETTINGS_FILE"
  fi
}

case "$(echo "${TG_API_KEY:-}" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes)
    set_api_enabled true
    echo "[start] REST-API enabled via TG_API_KEY=true (API key itself is managed in the app UI)."
    ;;
  false|0|no)
    set_api_enabled false
    echo "[start] REST-API disabled via TG_API_KEY=false."
    ;;
  *)
    echo "[start] TG_API_KEY not set (true/false) - API settings managed in the app UI."
    ;;
esac

# Window-Manager starten
fluxbox &

# VNC-Server starten
x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen 0.0.0.0 &

# noVNC via websockify (Web-UI auf Port 6080)
websockify --web /usr/share/novnc 6080 localhost:5900 &

# REST-API Proxy:
# Die App bindet die API bewusst nur auf 127.0.0.1:8550 (loopback-only).
# socat exponiert sie kontrolliert auf 0.0.0.0:8560 (extern gemappt als 8550,
# intern im highfishNetwork als http://telegram-drive:8560 erreichbar).
socat TCP-LISTEN:8560,fork,reuseaddr TCP:127.0.0.1:8550 &
echo "[start] REST-API proxy listening on 0.0.0.0:8560 -> 127.0.0.1:8550"

# Warte kurz bis X11 bereit ist
sleep 2

# Telegram-Drive starten
echo "Starting Telegram-Drive..."
exec /app/telegram-drive
