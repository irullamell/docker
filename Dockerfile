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
# REPLACE index.html novnc - auto redirect + auto connect
# ============================================================
RUN cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Loading VNC...</title>
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
        }
        .loader {
            text-align: center;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 5px solid #333;
            border-top: 5px solid #4fc3f7;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
    <script>
        // Redirect paksa ke vnc.html dengan autoconnect
        window.onload = function() {
            window.location.href = '/vnc.html?autoconnect=1&reconnect=1&reconnect_delay=2000&resize=scale&quality=6&compression=2&show_dot=false&path=websockify';
        };
    </script>
</head>
<body>
    <div class="loader">
        <div class="spinner"></div>
        <p>Connecting to Desktop...</p>
    </div>
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

RUN chown -R restricteduser:restricteduser /home/restricteduser/

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
set -e

echo "================================================"
echo " Starting Desktop Environment"
echo "================================================"

# ============================================================
# STEP 1: Cleanup VNC lock files lama
# ============================================================
echo "[1/6] Cleanup lock files..."
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -rf /home/restricteduser/.vnc/*.pid
rm -rf /home/restricteduser/.vnc/*.log

# ============================================================
# STEP 2: Fix permissions
# ============================================================
echo "[2/6] Fix permissions..."
chown -R restricteduser:restricteduser /home/restricteduser/
chmod 700 /home/restricteduser/.vnc
chmod 600 /home/restricteduser/.vnc/xstartup 2>/dev/null || true
chmod +x /home/restricteduser/.vnc/xstartup

# ============================================================
# STEP 3: Start VNC Server
# ============================================================
echo "[3/6] Starting VNC Server..."
su - restricteduser -s /bin/bash -c \
    "vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    -geometry 1280x720 \
    -depth 24 \
    --I-KNOW-THIS-IS-INSECURE \
    2>&1"

# Tunggu VNC benar-benar ready
echo "    Waiting for VNC to be ready..."
for i in $(seq 1 30); do
    if ss -tlnp | grep -q ':5901'; then
        echo "    VNC ready on port 5901 ✓"
        break
    fi
    echo "    Waiting... ($i/30)"
    sleep 1
done

# ============================================================
# STEP 4: Generate SSL Certificate
# ============================================================
echo "[4/6] Generating SSL certificate..."
openssl req -new \
    -subj "/C=JP/O=Desktop/CN=localhost" \
    -x509 -days 365 -nodes \
    -out /self.pem \
    -keyout /self.pem 2>/dev/null
echo "    SSL certificate generated ✓"

# ============================================================
# STEP 5: Start Websockify
# ============================================================
echo "[5/6] Starting websockify (noVNC)..."
websockify \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    --ssl-only=false \
    --log-file=/var/log/websockify.log \
    0.0.0.0:6080 \
    localhost:5901 &

WEBSOCKIFY_PID=$!
echo "    Websockify PID: $WEBSOCKIFY_PID"

# Tunggu websockify ready
sleep 3
if kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "    Websockify ready on port 6080 ✓"
else
    echo "    [ERROR] Websockify failed! Check log:"
    cat /var/log/websockify.log
    exit 1
fi

# ============================================================
# STEP 6: Blokir binary berbahaya
# ============================================================
echo "[6/6] Blocking dangerous binaries..."

BLOCK_LIST=(
    /usr/bin/xterm
    /usr/bin/xfce4-terminal
    /usr/bin/gnome-terminal
    /usr/bin/xfce4-appfinder
    /usr/bin/xfrun4
    /usr/bin/thunar
    /usr/bin/nautilus
    /usr/bin/pcmanfm
    /usr/bin/mousepad
    /usr/bin/gedit
    /usr/bin/vim
    /usr/bin/vi
    /usr/bin/nano
    /usr/bin/emacs
    /usr/bin/wget
    /usr/bin/curl
    /usr/bin/git
    /usr/bin/ssh
    /usr/bin/scp
    /usr/bin/ftp
    /usr/bin/telnet
    /usr/bin/nc
    /usr/bin/nmap
    /usr/bin/apt
    /usr/bin/apt-get
    /usr/bin/dpkg
    /usr/bin/snap
    /usr/bin/su
    /usr/bin/sudo
    /usr/bin/passwd
    /usr/bin/useradd
    /usr/bin/usermod
    /usr/bin/adduser
    /usr/bin/visudo
    /usr/bin/crontab
    /usr/bin/top
    /usr/bin/htop
    /usr/bin/strace
    /usr/bin/find
    /usr/bin/base64
    /usr/bin/xxd
    /usr/bin/zip
    /usr/bin/unzip
    /usr/bin/tar
    /usr/bin/rsync
    /usr/bin/nmcli
    /usr/bin/perl
    /usr/bin/ruby
    /usr/bin/php
    /usr/bin/lua
    /usr/bin/node
    /usr/bin/npm
)

BLOCKED=0
for binary in "${BLOCK_LIST[@]}"; do
    if [ -f "$binary" ]; then
        chmod 000 "$binary"
        BLOCKED=$((BLOCKED + 1))
    fi
done
echo "    Blocked $BLOCKED binaries ✓"

# ============================================================
# DONE
# ============================================================
echo ""
echo "================================================"
echo " Desktop Environment Ready!"
echo " Access: http://localhost:6080"
echo " VNC akan auto-connect"
echo "================================================"
echo ""

# Monitor processes
while true; do
    # Cek VNC masih jalan
    if ! su - restricteduser -s /bin/bash -c "vncserver -list 2>/dev/null" | grep -q ":1"; then
        echo "[!] VNC died, restarting..."
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
        su - restricteduser -s /bin/bash -c \
            "vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE"
    fi

    # Cek websockify masih jalan
    if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
        echo "[!] Websockify died, restarting..."
        websockify \
            --web=/usr/share/novnc/ \
            --cert=/self.pem \
            --ssl-only=false \
            --log-file=/var/log/websockify.log \
            0.0.0.0:6080 \
            localhost:5901 &
        WEBSOCKIFY_PID=$!
    fi

    sleep 10
done
STARTSCRIPT

RUN chmod +x /start.sh

EXPOSE 5901
EXPOSE 6080

CMD ["/start.sh"]
