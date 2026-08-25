# ============================================================
# Telegram-Drive Docker Container
# Multi-Stage Build für Tauri Desktop-App im Headless-Modus
# Build-Deps angelehnt an den offiziellen release.yml Workflow
# von caamer20/Telegram-Drive (Node 22, npm ci, libdbus-1-dev)
# ============================================================

# ------------------------------------------------------------
# Stage 1: Builder - Tauri-App kompilieren
# ------------------------------------------------------------
FROM node:22-bookworm AS builder

LABEL maintainer="hAI.TelegramDrivePortainer"

# Rust für Tauri-Backend installieren
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Tauri Linux-Abhängigkeiten (wie im offiziellen release.yml Workflow)
RUN apt-get update && apt-get install -y \
    libwebkit2gtk-4.1-dev \
    libssl-dev \
    libdbus-1-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    libjavascriptcoregtk-4.1-dev \
    libsoup-3.0-dev \
    build-essential \
    curl \
    wget \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Repository klonen
RUN git clone --depth 1 https://github.com/caamer20/Telegram-Drive.git /tmp/telegram-drive
RUN cp -r /tmp/telegram-drive/app/* /app/

# Dependencies exakt nach Lockfile installieren (wie offizieller Workflow)
RUN npm ci

# tauri.conf.json patchen:
# - createUpdaterArtifacts: false -> sonst bricht der Build ohne
#   TAURI_SIGNING_PRIVATE_KEY ab (Secret liegt nur im Original-Repo)
# - targets: ["deb"] statt "all" -> AppImage-Bundling via linuxdeploy
#   braucht FUSE (in Docker nicht vorhanden), RPM ist unnoetig.
#   Wir brauchen nur das Binary aus target/release.
RUN sed -i 's/"createUpdaterArtifacts": true/"createUpdaterArtifacts": false/' src-tauri/tauri.conf.json \
    && sed -i 's/"targets": "all"/"targets": ["deb"]/' src-tauri/tauri.conf.json \
    && grep -E 'createUpdaterArtifacts|"targets"' src-tauri/tauri.conf.json

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
# dbus-x11: dbus-launch (Session Bus, braucht die App fuer Tray + Secure Storage)
# gnome-keyring: Secret Service (Platform secure storage der App)
# socat: Proxy fuer die REST-API (App bindet bewusst nur 127.0.0.1)
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
    dbus-x11 \
    gnome-keyring \
    socat \
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

WORKDIR /app

# Binary aus Builder-Stage, Startscript + eigene noVNC-Landing-Page aus dem Repo
COPY --from=builder /app/telegram-drive-bin /app/telegram-drive
COPY start.sh /app/start.sh
COPY index.html /usr/share/novnc/index.html

RUN chmod +x /app/start.sh /app/telegram-drive

# Ports: VNC (5900), noVNC Web (6080), REST-API-Proxy (8560 intern -> extern 8550)
EXPOSE 5900 6080 8560

# Environment-Variablen
ENV VNC_PASSWORD=telegram123
ENV DISPLAY=:99

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:6080/ || exit 1

CMD ["/app/start.sh"]
