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

# Window-Manager starten
fluxbox &

# VNC-Server starten
x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen 0.0.0.0 &

# noVNC via websockify (Web-UI auf Port 6080)
websockify --web /usr/share/novnc 6080 localhost:5900 &

# Warte kurz bis X11 bereit ist
sleep 2

# Telegram-Drive starten
echo "Starting Telegram-Drive..."
exec /app/telegram-drive
