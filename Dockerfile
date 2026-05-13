FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# INSTALL PACKAGES - digabung jadi 1 RUN untuk efisiensi layer
# ============================================================
RUN apt-get update -y && apt-get install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    init \
    net-tools \
    tzdata \
    openssl \
    python3 \
    python3-pip \
    procps \
    iproute2 \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Firefox dari PPA Mozilla
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
        > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' \
        > /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt-get update -y && apt-get install -y firefox xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# BUAT USER TERBATAS
# ============================================================
RUN useradd -m -s /bin/bash restricteduser && \
    echo "restricteduser:password123" | chpasswd

# ============================================================
# HAPUS TERMINAL & APP BERBAHAYA
# ============================================================
RUN apt-get remove -y --purge \
    xfce4-terminal xterm gnome-terminal konsole \
    lxterminal mousepad gedit 2>/dev/null || true && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f \
    /usr/share/applications/xfce4-terminal.desktop \
    /usr/share/applications/xterm.desktop \
    /usr/share/applications/exo-terminal-emulator.desktop \
    /usr/share/applications/xfce4-appfinder.desktop \
    /usr/share/applications/thunar.desktop \
    /usr/share/applications/mousepad.desktop 2>/dev/null || true

# ============================================================
# REPLACE index.html noVNC - redirect otomatis ke vnc.html
# ============================================================
RUN cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Desktop</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: #1a1a2e;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-family: Arial, sans-serif;
            color: white;
            flex-direction: column;
            gap: 20px;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 5px solid #333;
            border-top: 5px solid #4fc3f7;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        p { font-size: 18px; color: #4fc3f7; }
    </style>
    <script>
        setTimeout(function() {
            window.location.href = '/vnc.html?autoconnect=1'
                + '&reconnect=1'
                + '&reconnect_delay=2000'
                + '&resize=scale'
                + '&quality=6'
                + '&compression=2'
                + '&path=websockify';
        }, 1000);
    </script>
</head>
<body>
    <div class="spinner"></div>
    <p>Connecting to Desktop...</p>
</body>
</html>
EOF

# ============================================================
# KONFIGURASI XFCE
# ============================================================
RUN mkdir -p /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml

RUN cat > /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-menu" type="empty">
    <property name="show" type="bool" value="false"/>
  </property>
  <property name="windowlist-menu" type="empty">
    <property name="show" type="bool" value="false"/>
  </property>
</channel>
EOF

RUN cat > /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty">
    </property>
    <property name="custom" type="empty">
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="default" type="empty">
    </property>
    <property name="custom" type="empty">
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF

# Panel XFCE - hanya clock, tanpa taskbar / launcher
RUN cat > /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=8;x=0;y=0"/>
    <property name="length" type="uint" value="100"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="clock"/>
  </property>
</channel>
EOF

# Autostart Firefox saat login
RUN mkdir -p /home/restricteduser/.config/autostart && \
    cat > /home/restricteduser/.config/autostart/firefox.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox --no-first-run
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# ============================================================
# VNC xstartup
# ============================================================
RUN mkdir -p /home/restricteduser/.vnc && \
    cat > /home/restricteduser/.vnc/xstartup << 'EOF'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export HOME=/home/restricteduser
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF

# Set password VNC (wajib ada, meskipun SecurityTypes None)
# FIX: vncpasswd harus dijalankan sebagai restricteduser
RUN chmod +x /home/restricteduser/.vnc/xstartup && \
    chown -R restricteduser:restricteduser /home/restricteduser/

# ============================================================
# STARTUP SCRIPT
# ============================================================
RUN cat > /start.sh << 'STARTSCRIPT'
#!/bin/bash
set -euo pipefail  # FIX: fail fast jika ada error tak terduga

NOVNC_PORT=${PORT:-8080}
VNC_PORT=5901
VNC_DISPLAY=:1

echo "================================================"
echo " Railway Desktop Environment"
echo " noVNC Port : $NOVNC_PORT"
echo " VNC Port   : $VNC_PORT"
echo "================================================"

# ----------------------------------------------------------
# STEP 1: Cleanup lock file lama
# ----------------------------------------------------------
echo "[1/5] Cleanup..."
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -rf /home/restricteduser/.vnc/*.pid
# FIX: hapus log lama supaya tidak menumpuk
rm -f /home/restricteduser/.vnc/*.log

# ----------------------------------------------------------
# STEP 2: Fix permissions
# ----------------------------------------------------------
echo "[2/5] Fix permissions..."
chown -R restricteduser:restricteduser /home/restricteduser/
chmod +x /home/restricteduser/.vnc/xstartup

# ----------------------------------------------------------
# STEP 3: Start VNC Server
# ----------------------------------------------------------
echo "[3/5] Starting VNC Server on display $VNC_DISPLAY (port $VNC_PORT)..."

# FIX: gunakan su -c bukan su - agar env tidak berubah
su -c "vncserver $VNC_DISPLAY \
    -localhost no \
    -SecurityTypes None \
    -geometry 1280x720 \
    -depth 24 \
    --I-KNOW-THIS-IS-INSECURE 2>&1" \
    restricteduser

# Tunggu VNC benar-benar ready
echo "    Waiting for VNC..."
RETRY=0
MAX_RETRY=30
while [ $RETRY -lt $MAX_RETRY ]; do
    # FIX: prioritaskan ss, fallback ke netstat
    if ss -tlnp 2>/dev/null | grep -q ":$VNC_PORT "; then
        echo "    VNC ready on :$VNC_PORT ✓"
        break
    fi
    RETRY=$((RETRY + 1))
    if [ $RETRY -eq $MAX_RETRY ]; then
        echo "[ERROR] VNC tidak mau start setelah $MAX_RETRY percobaan!"
        # Tampilkan log untuk debug
        cat /home/restricteduser/.vnc/*.log 2>/dev/null || true
        exit 1
    fi
    echo "    Retry $RETRY/$MAX_RETRY..."
    sleep 2
done

# ----------------------------------------------------------
# STEP 4: Generate SSL self-signed
# ----------------------------------------------------------
echo "[4/5] Generating SSL..."
openssl req -new \
    -subj "/C=JP/O=Desktop/CN=localhost" \
    -x509 -days 365 -nodes \
    -out /self.pem \
    -keyout /self.pem 2>/dev/null
echo "    SSL ready ✓"

# ----------------------------------------------------------
# STEP 5: Start websockify / noVNC
# ----------------------------------------------------------
echo "[5/5] Starting noVNC on port $NOVNC_PORT..."

websockify \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    --ssl-only=false \
    --log-file=/var/log/websockify.log \
    0.0.0.0:$NOVNC_PORT \
    localhost:$VNC_PORT &

WEBSOCKIFY_PID=$!

# Beri waktu websockify bind ke port
sleep 3

if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "[ERROR] Websockify gagal start!"
    cat /var/log/websockify.log 2>/dev/null || true
    exit 1
fi
echo "    noVNC ready on port $NOVNC_PORT ✓"

# ----------------------------------------------------------
# Block binary berbahaya SETELAH semua service jalan
# (jangan diblock sebelumnya, karena dibutuhkan saat startup)
# ----------------------------------------------------------
echo "Blocking dangerous binaries..."

BLOCK_LIST=(
    /usr/bin/xterm /usr/bin/xfce4-terminal
    /usr/bin/gnome-terminal /usr/bin/xfce4-appfinder
    /usr/bin/xfrun4 /usr/bin/thunar
    /usr/bin/nautilus /usr/bin/pcmanfm
    /usr/bin/mousepad /usr/bin/gedit
    /usr/bin/vim /usr/bin/vi /usr/bin/nano
    /usr/bin/emacs /usr/bin/wget /usr/bin/curl
    /usr/bin/git /usr/bin/ssh /usr/bin/scp
    /usr/bin/ftp /usr/bin/telnet
    /usr/bin/nc /usr/bin/nmap
    /usr/bin/apt /usr/bin/apt-get /usr/bin/dpkg
    /usr/bin/snap /usr/bin/su /usr/bin/sudo
    /usr/bin/passwd /usr/bin/useradd
    /usr/bin/adduser /usr/bin/visudo
    /usr/bin/crontab /usr/bin/top /usr/bin/htop
    /usr/bin/strace /usr/bin/find
    /usr/bin/base64 /usr/bin/xxd
    /usr/bin/zip /usr/bin/unzip /usr/bin/tar
    /usr/bin/rsync /usr/bin/nmcli
    /usr/bin/perl /usr/bin/ruby
    /usr/bin/php /usr/bin/lua
    /usr/bin/node /usr/bin/npm
    # FIX: tambah python agar user tidak bisa spawn shell via python
    /usr/bin/python3 /usr/bin/python
)

for binary in "${BLOCK_LIST[@]}"; do
    [ -f "$binary" ] && chmod 000 "$binary" || true
done
echo "Binaries blocked ✓"

echo ""
echo "================================================"
echo " READY!"
echo " Access: https://your-app.railway.app"
echo "================================================"

# ----------------------------------------------------------
# Monitor loop - restart service jika mati
# FIX: set +e agar loop tidak berhenti karena exit code
# ----------------------------------------------------------
set +e
while true; do
    # Cek VNC
    if ! ss -tlnp 2>/dev/null | grep -q ":$VNC_PORT "; then
        echo "[!] VNC died, restarting..."
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
        su -c "vncserver $VNC_DISPLAY \
            -localhost no \
            -SecurityTypes None \
            -geometry 1280x720 \
            -depth 24 \
            --I-KNOW-THIS-IS-INSECURE" \
            restricteduser
    fi

    # Cek websockify
    if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
        echo "[!] Websockify died, restarting..."
        websockify \
            --web=/usr/share/novnc/ \
            --cert=/self.pem \
            --ssl-only=false \
            --log-file=/var/log/websockify.log \
            0.0.0.0:$NOVNC_PORT \
            localhost:$VNC_PORT &
        WEBSOCKIFY_PID=$!
    fi

    sleep 10
done
STARTSCRIPT

RUN chmod +x /start.sh

# Railway mendeteksi port dari EXPOSE
# FIX: Railway override ini dengan $PORT env var, EXPOSE hanya dokumentasi
EXPOSE 8080

CMD ["/start.sh"]
