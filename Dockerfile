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

# Binary robust ermitteln: Name aus Cargo.toml, Fallback: erstes Executable
RUN BINARY_NAME=$(grep -m1 '^name' /app/src-tauri/Cargo.toml | cut -d'"' -f2) && \
    echo "Erwartetes Binary: ${BINARY_NAME}" && \
    if [ -f "/app/src-tauri/target/release/${BINARY_NAME}" ]; then \
      cp "/app/src-tauri/target/release/${BINARY_NAME}" /app/telegram-drive-bin; \
    else \
      BIN=$(find /app/src-tauri/target/release -maxdepth 1 -type f -executable ! -name '*.so' ! -name '*.d' | head -n1) && \
      echo "Fallback-Binary: ${BIN}" && \
      cp "${BIN}" /app/telegram-drive-bin; \
    fi

# ------------------------------------------------------------
# Stage 2: Runtime - Minimaler Container mit Xvfb + VNC
# ------------------------------------------------------------
FROM debian:bookworm-slim

LABEL maintainer="hAI.TelegramDrivePortainer"
LABEL org.opencontainers.image.source="https://github.com/jbkunama1/hAI.TelegramDrivePortainer"
LABEL org.opencontainers.image.description="Telegram-Drive as Docker Container with VNC access"
LABEL org.opencontainers.image.licenses="MIT"

# Laufzeit-Abhängigkeiten für Tauri/GTK + VNC-Stack
# (novnc aus Debian-Paket -> liegt unter /usr/share/novnc, zieht websockify mit)
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
    curl \
    x11vnc \
    xvfb \
    fluxbox \
    novnc \
    websockify \
    x11-xkb-utils \
    xfonts-base \
    xfonts-scalable \
    fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

# noVNC: vnc.html als index.html verlinken (Root-URL oeffnet direkt die UI)
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

WORKDIR /app

# Binary aus Builder-Stage kopieren
COPY --from=builder /app/telegram-drive-bin /app/telegram-drive

# Startscript
COPY <<'EOF' /app/start.sh
#!/bin/bash
set -e

# VNC-Passwort setzen (x11vnc-eigenes Tool, kein vncpasswd noetig)
mkdir -p ~/.vnc
x11vnc -storepasswd "${VNC_PASSWORD:-telegram123}" ~/.vnc/passwd

# Xvfb starten (virtuelles Display)
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

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
EOF

RUN chmod +x /app/start.sh /app/telegram-drive

# Ports: VNC (5900), noVNC Web (6080)
EXPOSE 5900 6080

# Environment-Variablen
ENV VNC_PASSWORD=telegram123
ENV DISPLAY=:99

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:6080/ || exit 1

CMD ["/app/start.sh"]
