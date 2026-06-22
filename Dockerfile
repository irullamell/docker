FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=/root
ENV USER=root
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# ===== SYSTEM BASE =====
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4-session \
    xfce4-terminal \
    xfdesktop4 \
    xfce4-panel \
    xfwm4 \
    xfconf \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    curl \
    wget \
    git \
    openssl \
    procps \
    net-tools \
    dbus \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    ca-certificates \
    gnupg \
    fonts-liberation \
    fonts-dejavu \
    fonts-noto \
    xclip \
    xsel \
    htop \
    libgl1-mesa-glx \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# ===== INSTALL GOOGLE CHROME =====
RUN wget -q -O /tmp/chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt update -y \
    && apt install -y --no-install-recommends /tmp/chrome.deb \
    && rm -f /tmp/chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# ===== CHROME WRAPPER =====
RUN cat > /usr/local/bin/chromium-browser << 'EOF'
#!/bin/bash
exec google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    "$@"
EOF
RUN chmod +x /usr/local/bin/chromium-browser

# ===== CHROME DEFAULT PREFERENCES =====
RUN mkdir -p /root/.config/google-chrome/Default && \
    cat > /root/.config/google-chrome/Default/Preferences << 'EOF'
{
  "profile": {
    "password_manager_enabled": false,
    "exit_type": "Normal",
    "exited_cleanly": true
  },
  "browser": {
    "enable_spellchecking": false,
    "show_home_button": true,
    "home_page": "about:blank",
    "show_bookmark_bar": false,
    "check_default_browser": false
  },
  "sync": {
    "suppress_start": true
  },
  "distribution": {
    "skip_first_run_ui": true,
    "show_welcome_page": false,
    "import_bookmarks": false,
    "do_not_create_desktop_shortcut": true,
    "do_not_create_quick_launch_shortcut": true,
    "do_not_launch_chrome": true,
    "make_chrome_default": false,
    "make_chrome_default_for_user": false,
    "suppress_first_run_default_browser_prompt": true
  }
}
EOF

RUN touch "/root/.config/google-chrome/First Run"

# ===== XFCE MINIMAL CONFIG =====
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml

RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="enable_animations" type="bool" value="false"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="unredirect_overlays" type="bool" value="false"/>
    <property name="vblank_mode" type="string" value="off"/>
  </property>
</channel>
EOF

RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfdesktop" version="1.0">
  <property name="desktop" type="empty">
    <property name="show-thumbnails" type="bool" value="false"/>
    <property name="show-file-icons" type="bool" value="false"/>
    <property name="single-workspace-mode" type="bool" value="true"/>
    <property name="menu-show-icons" type="bool" value="false"/>
  </property>
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0.1"/>
            <value type="double" value="0.1"/>
            <value type="double" value="0.1"/>
            <value type="double" value="1"/>
          </property>
          <property name="image-style" type="int" value="0"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# ===== XFCE AUTOSTART CHROME =====
RUN mkdir -p /root/.config/autostart && \
    cat > /root/.config/autostart/chrome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Google Chrome
Exec=google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --no-first-run --no-default-browser-check --disable-sync --disable-extensions --disable-background-networking --disable-breakpad --disable-client-side-phishing-detection --disable-default-apps --disable-hang-monitor --disable-metrics --disable-metrics-reporting --disable-translate --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-ipc-flooding-protection --password-store=basic --use-mock-keychain --window-size=1820,980 about:blank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# ===== TIGERVNC CONFIG =====
RUN mkdir -p /etc/tigervnc && \
    cat > /etc/tigervnc/vncserver-config-defaults << 'EOF'
localhost=no
SecurityTypes=None
IdleTimeout=0
alwaysShared=1
dontDisconnect=1
EOF

# ===== VNC XSTARTUP =====
RUN mkdir -p /root/.vnc && \
    cat > /root/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

eval $(dbus-launch --sh-syntax --exit-with-session)
export DBUS_SESSION_BUS_ADDRESS

exec startxfce4 &
EOF
RUN chmod +x /root/.vnc/xstartup

# ===== STARTUP SCRIPT =====
RUN cat > /usr/local/bin/start.sh << 'STARTSCRIPT'
#!/bin/bash

# ============================================
# Logging helper - semua output ke stdout
# agar Railway bisa capture log
# ============================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_section() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
}

# Redirect semua stderr ke stdout
exec 2>&1

log_section "🚀 VNC Browser Starting - Railway Mode"

# ===== ENV SETUP =====
VNC_PORT=${VNC_PORT:-5901}
NOVNC_PORT=${PORT:-6080}
RESOLUTION=${RESOLUTION:-1280x800}

log "PORT env dari Railway : ${PORT:-tidak ada, pakai 6080}"
log "noVNC Port            : $NOVNC_PORT"
log "VNC Port              : $VNC_PORT"
log "Resolution            : $RESOLUTION"
log "Hostname              : $(hostname)"
log "User                  : $(whoami)"
log "PWD                   : $(pwd)"

# ===== CEK BINARY =====
log_section "🔍 Cek Binary"
for bin in vncserver websockify openssl google-chrome-stable Xvnc; do
    path=$(which $bin 2>/dev/null)
    if [ -n "$path" ]; then
        log "✅ $bin => $path"
    else
        log "❌ $bin => NOT FOUND"
    fi
done

# ===== CEK PORT TERSEDIA =====
log_section "🔍 Cek Port"
log "Port yang dipakai Railway: $NOVNC_PORT"
if netstat -tuln 2>/dev/null | grep -q ":$NOVNC_PORT "; then
    log "⚠️  Port $NOVNC_PORT sudah dipakai!"
else
    log "✅ Port $NOVNC_PORT tersedia"
fi

# ===== CLEANUP =====
log_section "🧹 Cleanup"
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -rf /root/.vnc/*.pid
rm -rf /root/.vnc/*.log
log "✅ Cleanup selesai"

# ===== DBUS =====
log_section "🔧 Setup DBus"
mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system --fork 2>&1 && log "✅ dbus-daemon OK" || log "⚠️  dbus-daemon gagal (lanjut)"
sleep 1

# ===== XDG RUNTIME =====
mkdir -p /tmp/runtime-root
chmod 700 /tmp/runtime-root
log "✅ XDG_RUNTIME_DIR OK"

# ===== START VNC =====
log_section "🖥️  Starting TigerVNC"
log "Command: vncserver :1 -localhost no -SecurityTypes None -geometry $RESOLUTION -depth 24 -rfbport $VNC_PORT"

vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    -geometry $RESOLUTION \
    -depth 24 \
    -rfbport $VNC_PORT \
    --I-KNOW-THIS-IS-INSECURE

VNC_EXIT=$?
log "VNC exit code: $VNC_EXIT"

if [ $VNC_EXIT -ne 0 ]; then
    log "❌ VNC GAGAL START!"
    log "--- VNC Log ---"
    cat /root/.vnc/*.log 2>/dev/null || log "(tidak ada log)"
    log "--- Xvnc tersedia? ---"
    ls -la /usr/bin/Xvnc 2>/dev/null || log "Xvnc tidak ditemukan"
    log "--- tigervnc info ---"
    dpkg -l | grep -i tiger 2>/dev/null || log "tigervnc tidak terinstall"
    exit 1
fi

log "✅ VNC berhasil start"

# Tampilkan VNC log
log "--- VNC Log ---"
cat /root/.vnc/*.log 2>/dev/null | tail -20 || true

sleep 5

# ===== TEST DISPLAY =====
log_section "🔍 Test Display"
export DISPLAY=:1

if xdpyinfo > /dev/null 2>&1; then
    log "✅ Display :1 OK"
    xdpyinfo | grep -E "dimensions|depth" | head -5 | while read line; do
        log "   $line"
    done
else
    log "⚠️  Display belum siap, tunggu 5 detik..."
    sleep 5
    if xdpyinfo > /dev/null 2>&1; then
        log "✅ Display OK setelah retry"
    else
        log "❌ Display gagal, lanjut saja..."
    fi
fi

# ===== SSL CERT =====
log_section "🔐 Generate SSL Certificate"
openssl req \
    -new \
    -subj '/C=US/ST=State/L=City/O=Local/CN=localhost' \
    -x509 \
    -days 365 \
    -nodes \
    -out /tmp/novnc.pem \
    -keyout /tmp/novnc.pem \
    2>&1

if [ -f /tmp/novnc.pem ]; then
    log "✅ SSL cert OK: $(ls -lh /tmp/novnc.pem)"
else
    log "❌ SSL cert gagal dibuat!"
    exit 1
fi

# ===== START noVNC =====
log_section "🌍 Starting noVNC"
log "Command: websockify --web=/usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT"

# Cek novnc web ada
if [ -d /usr/share/novnc ]; then
    log "✅ noVNC web dir OK: $(ls /usr/share/novnc/)"
else
    log "❌ /usr/share/novnc tidak ditemukan!"
    exit 1
fi

websockify \
    --web=/usr/share/novnc/ \
    --cert=/tmp/novnc.pem \
    --min-backlog=32 \
    --daemon \
    $NOVNC_PORT \
    localhost:$VNC_PORT

NOVNC_EXIT=$?
log "websockify exit code: $NOVNC_EXIT"

if [ $NOVNC_EXIT -ne 0 ]; then
    log "❌ noVNC GAGAL!"
    log "--- noVNC Log ---"
    cat /tmp/novnc.log 2>/dev/null || log "(tidak ada log)"
    exit 1
fi

log "✅ noVNC berhasil start"
sleep 2

# ===== VERIFIKASI PORT LISTENING =====
log_section "🔍 Verifikasi Port"
sleep 2
if netstat -tuln 2>/dev/null | grep -q ":$NOVNC_PORT "; then
    log "✅ Port $NOVNC_PORT LISTENING"
else
    log "⚠️  Port $NOVNC_PORT belum listening, cek..."
    netstat -tuln 2>/dev/null | head -20 || ss -tuln | head -20
fi

if netstat -tuln 2>/dev/null | grep -q ":$VNC_PORT "; then
    log "✅ Port $VNC_PORT LISTENING"
else
    log "⚠️  Port $VNC_PORT belum listening"
fi

# ===== READY =====
log_section "✅ SISTEM SIAP"
log "🌐 Buka: https://YOUR-APP.railway.app/vnc.html"
log "📍 noVNC : port $NOVNC_PORT"
log "📍 VNC   : port $VNC_PORT"
echo ""

# ===== WATCHDOG =====
RESTART_COUNT=0
while true; do
    sleep 10

    # Cek VNC
    if ! vncserver -list 2>/dev/null | grep -q ":1"; then
        RESTART_COUNT=$((RESTART_COUNT + 1))
        log "⚠️  VNC crash! Restart #$RESTART_COUNT"
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
        vncserver :1 \
            -localhost no \
            -SecurityTypes None \
            -geometry $RESOLUTION \
            -depth 24 \
            -rfbport $VNC_PORT \
            --I-KNOW-THIS-IS-INSECURE \
            2>&1 | while read l; do log "VNC: $l"; done
        sleep 3
    fi

    # Cek noVNC
    if ! pgrep -f "websockify" > /dev/null; then
        log "⚠️  noVNC crash! Restarting..."
        websockify \
            --web=/usr/share/novnc/ \
            --cert=/tmp/novnc.pem \
            --min-backlog=32 \
            --daemon \
            $NOVNC_PORT \
            localhost:$VNC_PORT \
            2>&1 | while read l; do log "noVNC: $l"; done
    fi

    # Log status setiap 60 detik
    if [ $(($(date +%s) % 60)) -lt 10 ]; then
        log "💓 Heartbeat - VNC: $(vncserver -list 2>/dev/null | grep ':1' || echo 'DOWN') | websockify: $(pgrep -f websockify > /dev/null && echo 'UP' || echo 'DOWN')"
    fi
done
STARTSCRIPT

RUN chmod +x /usr/local/bin/start.sh

# ===== CLEANUP =====
RUN apt clean && \
    apt autoclean && \
    apt autoremove -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /root/.wget-hsts

# ===== INIT =====
RUN touch /root/.Xauthority && \
    mkdir -p /root/.vnc

EXPOSE 6080
EXPOSE 5901

ENTRYPOINT ["/usr/local/bin/start.sh"]
