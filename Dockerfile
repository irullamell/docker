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

# ===== CHROME FIRST RUN FLAG =====
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
Exec=google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --no-first-run \
    --no-default-browser-check \
    --disable-sync \
    --disable-extensions \
    --disable-background-networking \
    --disable-breakpad \
    --disable-client-side-phishing-detection \
    --disable-default-apps \
    --disable-hang-monitor \
    --disable-metrics \
    --disable-metrics-reporting \
    --disable-translate \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-ipc-flooding-protection \
    --password-store=basic \
    --use-mock-keychain \
    --window-size=1820,980 \
    about:blank
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

echo "================================================"
echo "  🚀 VNC Browser - Railway Ready                "
echo "================================================"

# Railway inject $PORT otomatis, fallback ke 6080
VNC_PORT=${VNC_PORT:-5901}
NOVNC_PORT=${PORT:-6080}
RESOLUTION=${RESOLUTION:-1280x800}

echo "📌 noVNC Port : $NOVNC_PORT"
echo "📌 VNC Port   : $VNC_PORT"
echo "📌 Resolution : $RESOLUTION"
echo ""

# ===== CLEANUP =====
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1
rm -rf /root/.vnc/*.pid
rm -rf /root/.vnc/*.log

# ===== DBUS =====
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true
sleep 1

# ===== XDG RUNTIME =====
mkdir -p /tmp/runtime-root
chmod 700 /tmp/runtime-root

# ===== START VNC =====
echo "🖥️  Starting TigerVNC..."
vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    -geometry $RESOLUTION \
    -depth 24 \
    -rfbport $VNC_PORT \
    --I-KNOW-THIS-IS-INSECURE \
    2>/tmp/vnc.log

if [ $? -ne 0 ]; then
    echo "❌ VNC gagal start! Log:"
    cat /tmp/vnc.log
    exit 1
fi

echo "✅ VNC OK"
sleep 4

# ===== TEST DISPLAY =====
export DISPLAY=:1
xdpyinfo > /dev/null 2>&1 || sleep 3

# ===== SSL CERTIFICATE =====
echo "🔐 Generate SSL..."
openssl req \
    -new \
    -subj '/C=US/ST=State/L=City/O=Local/CN=localhost' \
    -x509 \
    -days 365 \
    -nodes \
    -out /tmp/novnc.pem \
    -keyout /tmp/novnc.pem \
    2>/dev/null

# ===== START noVNC =====
echo "🌍 Starting noVNC on port $NOVNC_PORT..."
websockify \
    --web=/usr/share/novnc/ \
    --cert=/tmp/novnc.pem \
    --min-backlog=32 \
    --daemon \
    $NOVNC_PORT \
    localhost:$VNC_PORT \
    2>/tmp/novnc.log

if [ $? -ne 0 ]; then
    echo "❌ noVNC gagal! Log:"
    cat /tmp/novnc.log
    exit 1
fi

echo "✅ noVNC OK"
echo ""
echo "================================================"
echo "✅ SEMUA BERJALAN!"
echo "================================================"
echo "🌐 Buka: https://YOUR-APP.railway.app/vnc.html"
echo "================================================"
echo ""

# ===== WATCHDOG LOOP =====
while true; do
    # Restart VNC jika crash
    if ! vncserver -list 2>/dev/null | grep -q ":1"; then
        echo "⚠️  VNC crash! Restarting..."
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
        vncserver :1 \
            -localhost no \
            -SecurityTypes None \
            -geometry $RESOLUTION \
            -depth 24 \
            -rfbport $VNC_PORT \
            --I-KNOW-THIS-IS-INSECURE \
            2>/dev/null
        sleep 3
    fi

    # Restart noVNC jika crash
    if ! pgrep -f "websockify" > /dev/null; then
        echo "⚠️  noVNC crash! Restarting..."
        websockify \
            --web=/usr/share/novnc/ \
            --cert=/tmp/novnc.pem \
            --min-backlog=32 \
            --daemon \
            $NOVNC_PORT \
            localhost:$VNC_PORT \
            2>/dev/null
    fi

    sleep 10
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
