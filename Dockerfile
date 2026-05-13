FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# INSTALL PACKAGES
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
    wget \
    bzip2 \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libx11-xcb1 \
    libxt6 \
    libpci3 \
    xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# INSTALL FIREFOX - wget dengan -L untuk follow redirect
# URL download.mozilla.org melakukan redirect ke CDN,
# tanpa -L wget hanya download HTML redirect bukan file asli
# ============================================================
RUN wget -qL \
        "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" \
        -O /tmp/firefox.tar.bz2 \
    && file /tmp/firefox.tar.bz2 \
    && tar -xjf /tmp/firefox.tar.bz2 -C /opt/ \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && rm /tmp/firefox.tar.bz2

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
# REPLACE index.html noVNC
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
# ============================================================
RUN cat > /start.sh << 'STARTSCRIPT'
#!/bin/bash

NOVNC_PORT=${PORT:-8080}
VNC_PORT=5901
VNC_DISPLAY=:1

echo "================================================"
echo " Railway Desktop Environment"
echo " noVNC Port : $NOVNC_PORT"
echo " VNC Port   : $VNC_PORT"
echo "================================================"

echo "[1/5] Cleanup..."
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -f /home/restricteduser/.vnc/*.pid
rm -f /home/restricteduser/.vnc/*.log

echo "[2/5] Fix permissions..."
chown -R restricteduser:restricteduser /home/restricteduser/
chmod +x /home/restricteduser/.vnc/xstartup

echo "[3/5] Starting VNC Server on display $VNC_DISPLAY..."
su -c "vncserver $VNC_DISPLAY \
    -localhost no \
    -SecurityTypes None \
    -geometry 1280x720 \
    -depth 24 \
    --I-KNOW-THIS-IS-INSECURE 2>&1" \
    restricteduser

echo "    Waiting for VNC..."
RETRY=0
MAX_RETRY=30
while [ $RETRY -lt $MAX_RETRY ]; do
    if ss -tlnp 2>/dev/null | grep -q ":$VNC_PORT "; then
        echo "    VNC ready ✓"
        break
    fi
    RETRY=$((RETRY + 1))
    if [ $RETRY -eq $MAX_RETRY ]; then
        echo "[ERROR] VNC gagal start!"
        cat /home/restricteduser/.vnc/*.log 2>/dev/null || true
        exit 1
    fi
    echo "    Retry $RETRY/$MAX_RETRY..."
    sleep 2
done

echo "[4/5] Generating SSL..."
openssl req -new \
    -subj "/C=JP/O=Desktop/CN=localhost" \
    -x509 -days 365 -nodes \
    -out /self.pem \
    -keyout /self.pem 2>/dev/null
echo "    SSL ready ✓"

echo "[5/5] Starting noVNC on port $NOVNC_PORT..."
websockify \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    --ssl-only=false \
    --log-file=/var/log/websockify.log \
    0.0.0.0:$NOVNC_PORT \
    localhost:$VNC_PORT &

WEBSOCKIFY_PID=$!
sleep 3

if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "[ERROR] Websockify gagal start!"
    cat /var/log/websockify.log 2>/dev/null || true
    exit 1
fi
echo "    noVNC ready on port $NOVNC_PORT ✓"

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
    /usr/bin/bzip2 /usr/bin/rsync /usr/bin/nmcli
    /usr/bin/perl /usr/bin/ruby
    /usr/bin/php /usr/bin/lua
    /usr/bin/node /usr/bin/npm
    /usr/bin/python3 /usr/bin/python
)
for binary in "${BLOCK_LIST[@]}"; do
    [ -f "$binary" ] && chmod 000 "$binary" || true
done
echo "Binaries blocked ✓"

echo ""
echo "================================================"
echo " READY! Access: https://your-app.railway.app"
echo "================================================"

while true; do
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

EXPOSE 8080

CMD ["/start.sh"]
