FROM --platform=linux/amd64 fedora:41

# ── Single layer install ─────────────────────────────────
RUN dnf update -y && dnf install -y \
    # ── KDE Plasma 6 (Qt6) ──
    plasma-desktop \
    plasma-workspace \
    plasma-systemsettings \
    plasma-nm \
    plasma-pa \
    kwin-x11 \
    breeze-icon-theme \
    breeze-cursor-theme \
    breeze-gtk \
    # ── Fonts ──
    google-noto-sans-fonts \
    google-noto-emoji-color-fonts \
    dejavu-sans-fonts \
    # ── KDE Apps ──
    konsole \
    dolphin \
    kate \
    spectacle \
    # ── VNC + noVNC ──
    tigervnc-server \
    novnc \
    python3-websockify \
    # ── Browser (latest, bukan ESR) ──
    firefox \
    # ── X11 / DBus ──
    dbus-x11 \
    xorg-x11-utils \
    xorg-x11-server-utils \
    xorg-x11-xinit \
    # ── Modern CLI Tools ──
    sudo \
    vim-minimal \
    net-tools \
    curl \
    wget \
    git \
    ca-certificates \
    openssl \
    tzdata \
    procps-ng \
    fastfetch \
    btop \
    zsh \
  && dnf clean all \
  && rm -rf /var/cache/dnf/*

# ── Disable KWin compositor (tidak ada GPU di container) ─
RUN mkdir -p /root/.config && \
    printf '[Compositing]\nEnabled=false\n' \
    > /root/.config/kwinrc

# ── Startup script ───────────────────────────────────────
RUN cat <<'STARTUP' > /start.sh
#!/bin/bash
set -e

# SSL cert untuk noVNC
openssl req -new -subj "/C=JP" -x509 -days 365 \
  -nodes -out /tmp/self.pem -keyout /tmp/self.pem 2>/dev/null

# XDG runtime
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

# Start Xvnc (display :1 = port 5901)
Xvnc :1 \
  -geometry 1920x1080 \
  -depth 24 \
  -SecurityTypes None \
  -localhost no \
  -AlwaysShared &
sleep 2

export DISPLAY=:1

# D-Bus session
eval "$(dbus-launch --sh-syntax)"

# KDE Environment
export DESKTOP_SESSION=plasma
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=KDE
export KWIN_COMPOSE=N

# Launch Plasma 6
startplasma-x11 &

# noVNC websocket proxy
websockify -D \
  --web=/usr/share/novnc/ \
  --cert=/tmp/self.pem \
  6080 localhost:5901

echo "╔══════════════════════════════════════╗"
echo "║  Desktop ready!                      ║"
echo "║  https://localhost:6080/vnc.html     ║"
echo "╚══════════════════════════════════════╝"

tail -f /dev/null
STARTUP
chmod +x /start.sh

RUN touch /root/.Xauthority

EXPOSE 5901 6080

CMD ["/start.sh"]
