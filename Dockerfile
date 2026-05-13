FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt install --no-install-recommends -y \
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
    && apt update -y && apt install -y \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    && apt install -y software-properties-common

RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | \
    tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt update -y && apt install -y firefox && \
    apt update -y && apt install -y xubuntu-icon-theme

# Buat user terbatas
RUN useradd -m -s /bin/bash restricteduser && \
    echo "restricteduser:password123" | chpasswd

# Hapus terminal & app berbahaya
RUN apt remove -y --purge \
    xfce4-terminal xterm gnome-terminal konsole \
    lxterminal mousepad gedit 2>/dev/null || true

RUN rm -f \
    /usr/share/applications/xfce4-terminal.desktop \
    /usr/share/applications/xterm.desktop \
    /usr/share/applications/exo-terminal-emulator.desktop \
    /usr/share/applications/xfce4-appfinder.desktop \
    /usr/share/applications/thunar.desktop \
    /usr/share/applications/mousepad.desktop 2>/dev/null || true

# ============================================================
# REPLACE index.html novnc
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
        function redirect() {
            var host = window.location.hostname;
            var port = window.location.port;
            var protocol = window.location.protocol;
            var wsProtocol = protocol === 'https:' ? 'wss' : 'ws';

            // Build URL dengan path yang benar
            var url = '/vnc.html?autoconnect=1' +
                      '&reconnect=1' +
                      '&reconnect_delay=2000' +
                      '&resize=scale' +
                      '&quality=6' +
                      '&compression=2' +
                      '&path=websockify';

            window.location.href = url;
        }
        // Redirect setelah 1 detik
        setTimeout(redirect, 1000);
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

RUN chmod +x /home/restricteduser/.vnc/xstartup && \
    chown -R restricteduser:restricteduser /home/restricteduser/

# ============================================================
# STARTUP SCRIPT
# Railway inject $PORT environment variable
# Kita harus listen di $PORT bukan hardcode 6080
# ============================================================
RUN cat > /start.sh << 'STARTSCRIPT'
#!/bin/bash

# ============================================================
# Railway menggunakan $PORT environment variable
# Default fallback ke 8080 jika tidak ada
# ============================================================
NOVNC_PORT=${PORT:-8080}
VNC_PORT=5901
VNC_DISPLAY=:1

echo "================================================"
echo " Railway Desktop Environment"
echo " noVNC Port : $NOVNC_PORT"
echo " VNC Port   : $VNC_PORT"
echo "================================================"

# ============================================================
# STEP 1: Cleanup
# ============================================================
echo "[1/5] Cleanup..."
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -rf /home/restricteduser/.vnc/*.pid
rm -rf /home/restricteduser/.vnc/*.log

# ============================================================
# STEP 2: Fix permissions
# ============================================================
echo "[2/5] Fix permissions..."
chown -R restricteduser:restricteduser /home/restricteduser/
chmod +x /home/restricteduser/.vnc/xstartup

# ============================================================
# STEP 3: Start VNC Server
# ============================================================
echo "[3/5] Starting VNC Server on $VNC_PORT..."
su - restricteduser -s /bin/bash -c \
    "vncserver $VNC_DISPLAY \
    -localhost no \
    -SecurityTypes None \
    -geometry 1280x720 \
    -depth 24 \
    --I-KNOW-THIS-IS-INSECURE" 2>&1

# Tunggu VNC ready
echo "    Waiting for VNC..."
RETRY=0
while [ $RETRY -lt 30 ]; do
    if ss -tlnp 2>/dev/null | grep -q ":$VNC_PORT" || \
       netstat -tlnp 2>/dev/null | grep -q ":$VNC_PORT"; then
        echo "    VNC ready ✓"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "    Retry $RETRY/30..."
    sleep 2
done

# ============================================================
# STEP 4: Generate SSL
# ============================================================
echo "[4/5] Generating SSL..."
openssl req -new \
    -subj "/C=JP/O=Desktop/CN=localhost" \
    -x509 -days 365 -nodes \
    -out /self.pem \
    -keyout /self.pem 2>/dev/null
echo "    SSL ready ✓"

# ============================================================
# STEP 5: Start Websockify di PORT yang Railway berikan
# ============================================================
echo "[5/5] Starting noVNC on port $NOVNC_PORT..."

# Jalankan websockify foreground agar Railway tahu app sudah ready
websockify \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    --ssl-only=false \
    --log-file=/var/log/websockify.log \
    0.0.0.0:$NOVNC_PORT \
    localhost:$VNC_PORT &

WEBSOCKIFY_PID=$!

# Tunggu websockify ready
sleep 3

if kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "    noVNC ready on port $NOVNC_PORT ✓"
else
    echo "[ERROR] Websockify failed!"
    cat /var/log/websockify.log
    exit 1
fi

echo ""
echo "================================================"
echo " READY!"
echo " Access: https://your-app.railway.app"
echo "================================================"

# ============================================================
# Block binary berbahaya setelah semua service jalan
# ============================================================
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
)

for binary in "${BLOCK_LIST[@]}"; do
    if [ -f "$binary" ]; then
        chmod 000 "$binary"
    fi
done
echo "Binaries blocked ✓"

# ============================================================
# Monitor - keep container alive & restart jika mati
# ============================================================
while true; do
    # Cek VNC
    if ! su - restricteduser -s /bin/bash -c \
        "vncserver -list 2>/dev/null" | grep -q "$VNC_DISPLAY"; then
        echo "[!] VNC died, restarting..."
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
        su - restricteduser -s /bin/bash -c \
            "vncserver $VNC_DISPLAY \
            -localhost no \
            -SecurityTypes None \
            -geometry 1280x720 \
            -depth 24 \
            --I-KNOW-THIS-IS-INSECURE"
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

# Railway detect port dari EXPOSE
EXPOSE 8080

CMD ["/start.sh"]
