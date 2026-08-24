# ============================================================
# Telegram-Drive Docker Container
# Multi-Stage Build für Tauri Desktop-App im Headless-Modus
# ============================================================

# ------------------------------------------------------------
# Stage 1: Builder - Tauri-App kompilieren
# ------------------------------------------------------------
FROM node:20-bookworm AS builder

LABEL maintainer="hAI.TelegramDrivePortainer"

# Rust für Tauri-Backend installieren
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Tauri Linux-Abhängigkeiten installieren
RUN apt-get update && apt-get install -y \
    libwebkit2gtk-4.1-dev \
    build-essential \
    curl \
    wget \
    file \
    libxdo-dev \
    libssl-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    libgtk-3-dev \
    libjavascriptcoregtk-4.1-dev \
    libsoup-3.0-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gperf \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Repository klonen
RUN git clone --depth 1 https://github.com/caamer20/Telegram-Drive.git /tmp/telegram-drive
RUN cp -r /tmp/telegram-drive/app/* /app/

# Dependencies installieren
RUN npm install

# Tauri-App bauen (Release-Build)
ENV CI=true
RUN npm run tauri build

# ------------------------------------------------------------
# Stage 2: Runtime - Minimaler Container mit Xvfb + VNC
# ------------------------------------------------------------
FROM debian:bookworm-slim

LABEL maintainer="hAI.TelegramDrivePortainer"
LABEL org.opencontainers.image.source="https://github.com/jbkunama1/hAI.TelegramDrivePortainer"
LABEL org.opencontainers.image.description="Telegram-Drive as Docker Container with VNC access"
LABEL org.opencontainers.image.licenses="MIT"

# Laufzeit-Abhängigkeiten für Tauri/GTK
RUN apt-get update && apt-get install -y \
    libwebkit2gtk-4.1-0 \
    libxdo3 \
    libssl3 \
    libayatana-appindicator3-1 \
    librsvg2-2 \
    libgtk-3-0 \
    libjavascriptcoregtk-4.1-0 \
    libsoup-3.0-0 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    ca-certificates \
    x11vnc \
    xvfb \
    fluxbox \
    novnc \
    websockify \
    supervisor \
    x11-xkb-utils \
    xfonts-base \
    xfonts-scalable \
    fonts-courier \
    fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

# noVNC Web-Interface einrichten
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && cd /opt/novnc \
    && ln -s vnc.html index.html

WORKDIR /app

# Binary aus Builder-Stage kopieren
COPY --from=builder /app/src-tauri/target/release/telegram-drive /app/telegram-drive

# Startscript
COPY <<'EOF' /app/start.sh
#!/bin/bash
set -e

# VNC-Passwort setzen (standard: telegram123)
mkdir -p ~/.vnc
echo "${VNC_PASSWORD:-telegram123}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Xvfb starten (virtuelles Display)
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# Window-Manager starten
fluxbox &

# VNC-Server starten
x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen 0.0.0.0 &

# noVNC WebSocket-Proxy starten
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Warte kurz bis X11 bereit ist
sleep 2

# Telegram-Drive starten
echo "Starting Telegram-Drive..."
exec /app/telegram-drive
EOF

RUN chmod +x /app/start.sh

# Ports: VNC (5900), noVNC Web (6080)
EXPOSE 5900 6080

# Environment-Variablen
ENV VNC_PASSWORD=telegram123
ENV DISPLAY=:99

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -x telegram-drive || exit 1

CMD ["/app/start.sh"]
