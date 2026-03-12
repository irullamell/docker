FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# ── Satu layer, bersihkan cache ──────────────────────────
RUN apt-get update && apt-get install --no-install-recommends -y \
    # ── Desktop ──
    xfce4 \
    xfce4-terminal \
    adwaita-icon-theme \
    tango-icon-theme \
    fonts-dejavu \
    fonts-noto-color-emoji \
    # ── VNC + noVNC ──
    tigervnc-standalone-server \
    novnc \
    websockify \
    # ── Browser ──
    firefox-esr \
    # ── X11 / DBus ──
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    # ── Tools ──
    sudo \
    xterm \
    vim-tiny \
    net-tools \
    curl \
    wget \
    git \
    ca-certificates \
    openssl \
    tzdata \
    procps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN touch /root/.Xauthority

EXPOSE 5901 6080

CMD ["bash", "-c", "\
  vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    -geometry 1024x768 \
    --I-KNOW-THIS-IS-INSECURE \
  && openssl req -new -subj '/C=JP' -x509 -days 365 \
    -nodes -out /tmp/self.pem -keyout /tmp/self.pem \
  && websockify -D \
    --web=/usr/share/novnc/ \
    --cert=/tmp/self.pem \
    6080 localhost:5901 \
  && tail -f /dev/null"]
