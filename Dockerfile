FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ===== SYSTEM BASE + ESSENTIALS =====
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4-session xfce4-terminal xfdesktop4 xfce4-panel xfce4-whiskermenu-plugin \
    xfce4-power-manager xfwm4 xfconf \
    tigervnc-standalone-server novnc websockify \
    sudo curl wget git \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    software-properties-common ca-certificates \
    pulseaudio pavucontrol \
    snapd

# ===== INSTALL CHROMIUM FROM SNAP (RELIABLE) =====
RUN snap install chromium

# ===== CREATE CHROMIUM WRAPPER FOR EASIER USAGE =====
RUN mkdir -p /usr/local/bin && \
    cat > /usr/local/bin/chromium-browser << 'WRAPPER'
#!/bin/bash
exec /snap/bin/chromium "$@"
WRAPPER

RUN chmod +x /usr/local/bin/chromium-browser

# ===== CHROMIUM PERFORMANCE CONFIGURATION =====
RUN mkdir -p /root/.config/chromium/Default && \
    cat > /root/.config/chromium/Default/Preferences << 'EOF'
{
  "profile": {
    "password_manager_enabled": false,
    "default_content_settings": {
      "plugins": [{"setting": 1}]
    },
    "content_settings": {
      "pattern_pairs": {
        "https://[*.]/*,*": {
          "media_stream": 1,
          "media_stream_mic": 1,
          "media_stream_camera": 1,
          "notifications": 1
        }
      }
    }
  },
  "browser": {
    "enable_spellchecking": false,
    "enable_do_not_track": false,
    "show_home_button": true,
    "home_page": "about:blank",
    "show_bookmark_bar": true
  },
  "media": {
    "cache": true,
    "cache_size": 1073741824
  },
  "net": {
    "network_prediction_options": 2,
    "enable_quic": true
  },
  "sync": {
    "managed": false,
    "suppress_start": true
  },
  "extensions": {
    "theme": {
      "colors": {}
    }
  }
}
EOF

# ===== SYSTEM KERNEL TUNING =====
RUN cat >> /etc/sysctl.conf << 'EOF'
# VM Memory Management
vm.swappiness=5
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.extra_free_kbytes=262144

# Network Tuning for Streaming/Browsing
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_dsack=1
net.ipv4.tcp_fack=1
net.core.netdev_max_backlog=8192
net.ipv4.tcp_max_syn_backlog=8192
net.core.somaxconn=2048
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_max_tw_buckets=1440000
net.core.rmem_default=262144
net.core.rmem_max=536870912
net.core.wmem_default=262144
net.core.wmem_max=536870912
net.ipv4.tcp_rmem=4096 87380 536870912
net.ipv4.tcp_wmem=4096 65536 536870912
net.core.tcp_max_backlog=8192
net.ipv4.tcp_low_latency=1

# File Descriptors
fs.file-max=2097152
fs.inotify.max_user_watches=524288
EOF

# ===== LIGHTWEIGHT XFCE OPTIMIZATION =====
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="activate_raise" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="focus_new_windows" type="int" value="0"/>
    <property name="raise_on_click" type="bool" value="true"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="enable_animations" type="bool" value="false"/>
    <property name="cycle_minimized" type="bool" value="false"/>
    <property name="tile_on_move" type="bool" value="true"/>
    <property name="unredirect_overlays" type="bool" value="true"/>
    <property name="use_compositing" type="bool" value="true"/>
  </property>
</channel>
EOF

# XFCE Desktop Configuration
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfdesktop" version="1.0">
  <property name="desktop" type="empty">
    <property name="show-thumbnails" type="bool" value="false"/>
    <property name="show-file-icons" type="bool" value="false"/>
    <property name="font-size" type="int" value="11"/>
    <property name="single-workspace-mode" type="bool" value="true"/>
  </property>
</channel>
EOF

# XFCE Panel Configuration
RUN mkdir -p /root/.config/xfce4/panel && \
    cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
      </property>
    </property>
  </property>
</channel>
EOF

# ===== CREATE STARTUP SCRIPT =====
RUN mkdir -p /usr/local/bin && \
    cat > /usr/local/bin/start.sh << 'STARTSCRIPT'
#!/bin/bash
set -e

echo "==============================================="
echo "  🚀 Chromium Heavy Browsing Optimization Mode  "
echo "==============================================="
echo ""

echo "⚙️  Optimizing system kernel..."
sysctl -p > /dev/null 2>&1

echo "💾 Clearing cache..."
sync
echo 3 > /proc/sys/vm/drop_caches

echo "🖥️  Starting VNC Server on :1 (5901)..."
vncserver \
    -localhost no \
    -SecurityTypes None \
    -geometry 1920x1080 \
    -depth 24 \
    -rfbport 5901 \
    --I-KNOW-THIS-IS-INSECURE

sleep 3

echo "🌐 Starting Chromium Browser..."
export DISPLAY=:1
export SNAP_USER_DATA=/root/snap

/snap/bin/chromium \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-breakpad \
    --disable-client-side-phishing-detection \
    --disable-default-apps \
    --disable-extensions \
    --disable-features=InterestFeedContentSuggestions,Translate \
    --disable-file-system-api \
    --disable-geolocation \
    --disable-hang-monitor \
    --disable-metrics \
    --disable-sync \
    --enable-gpu \
    --enable-gpu-compositing \
    --enable-native-gpu-memory-buffers \
    --enable-zero-copy \
    --enable-quic \
    --ignore-gpu-blacklist \
    --force-gpu-mem-available-mb=2048 \
    --password-store=basic \
    --use-mock-keychain \
    --no-default-browser-check \
    --process-per-site \
    --renderer-process-limit=128 \
    about:blank > /dev/null 2>&1 &

sleep 2

echo "🔐 Generating SSL Certificate..."
openssl req -new -subj '/C=JP/ST=Tokyo/L=Tokyo/O=Local/CN=localhost' \
    -x509 -days 365 -nodes -out self.pem -keyout self.pem 2>/dev/null

echo "🌍 Starting WebSocket Proxy on 6080..."
websockify -D \
    --web=/usr/share/novnc/ \
    --cert=self.pem \
    --min-backlog=64 \
    6080 localhost:5901

echo ""
echo "==============================================="
echo "✅ SYSTEM READY FOR HEAVY BROWSING!"
echo "==============================================="
echo ""
echo "📍 Access VNC at: http://localhost:6080"
echo "📍 VNC Port: 5901"
echo "📍 Browser: Chromium (Snap - Optimized)"
echo "📍 Resolution: 1920x1080"
echo ""

tail -f /dev/null
STARTSCRIPT

RUN chmod +x /usr/local/bin/start.sh

# ===== OPTIONAL: ADDITIONAL TOOLS =====
RUN apt install -y --no-install-recommends \
    htop iotop \
    mesa-utils libgl1-mesa-glx \
    fonts-liberation fonts-dejavu \
    xclip xsel \
    gpg gpg-agent

# ===== TigerVNC OPTIMIZATION =====
RUN mkdir -p /etc/tigervnc && \
    cat > /etc/tigervnc/vncserver-config-defaults << 'EOF'
# TigerVNC Server optimization
localhost=no
SecurityTypes=None
IdleTimeout=0
MaxConnectionTime=0
MaxDisconnectionTime=0
MaxIdleTime=0
protocol3.3=1
alwaysShared=1
dontDisconnect=1
FrameRate=60
ApparentFrameRate=60
CompareFB=0
UsesRFBV6=0
EOF

# ===== USER SETUP =====
RUN useradd -m -s /bin/bash -G sudo,audio,video,render,snap_core user && \
    echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/user/.config/chromium/Default && \
    cp /root/.config/chromium/Default/Preferences /home/user/.config/chromium/Default/ 2>/dev/null || true && \
    chown -R user:user /home/user

# ===== SHARED MEMORY FIX =====
RUN echo "* soft memlock unlimited" >> /etc/security/limits.conf && \
    echo "* hard memlock unlimited" >> /etc/security/limits.conf

# ===== CLEANUP =====
RUN apt clean && \
    apt autoclean && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

# ===== INITIALIZATION =====
RUN touch /root/.Xauthority

EXPOSE 5901
EXPOSE 6080

# ===== START =====
ENTRYPOINT ["/usr/local/bin/start.sh"]
