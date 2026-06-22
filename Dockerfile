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
    software-properties-common ca-certificates gnupg \
    pulseaudio pavucontrol \
    openssl \
    htop iotop \
    mesa-utils libgl1-mesa-glx \
    fonts-liberation fonts-dejavu \
    xclip xsel \
    gpg gpg-agent && \
    rm -rf /var/lib/apt/lists/*

# ===== INSTALL CHROMIUM VIA APT (BUKAN SNAP) =====
# Metode 1: Langsung dari Ubuntu repo (chromium-browser di 22.04 redirect ke snap, skip)
# Metode 2: Gunakan Google Chrome stable sebagai alternatif terpercaya
RUN wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt update -y && \
    apt install -y --no-install-recommends /tmp/google-chrome.deb && \
    rm -f /tmp/google-chrome.deb && \
    rm -rf /var/lib/apt/lists/*

# ===== ATAU: Gunakan Chromium dari Debian/PPA =====
# Uncomment blok ini jika ingin Chromium murni (bukan Chrome)
# RUN add-apt-repository ppa:xtradeb/apps -y && \
#     apt update -y && \
#     apt install -y --no-install-recommends chromium && \
#     rm -rf /var/lib/apt/lists/*

# ===== CHROMIUM/CHROME WRAPPER =====
RUN cat > /usr/local/bin/chromium-browser << 'WRAPPER'
#!/bin/bash
exec google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    "$@"
WRAPPER
RUN chmod +x /usr/local/bin/chromium-browser

# ===== CHROME PERFORMANCE CONFIGURATION =====
RUN mkdir -p /root/.config/google-chrome/Default && \
    cat > /root/.config/google-chrome/Default/Preferences << 'EOF'
{
  "profile": {
    "password_manager_enabled": false
  },
  "browser": {
    "enable_spellchecking": false,
    "enable_do_not_track": false,
    "show_home_button": true,
    "home_page": "about:blank",
    "show_bookmark_bar": true
  },
  "net": {
    "network_prediction_options": 2
  },
  "sync": {
    "suppress_start": true
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

# Network Tuning
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_sack=1
net.core.netdev_max_backlog=8192
net.core.somaxconn=2048
net.ipv4.ip_local_port_range=1024 65535
net.core.rmem_default=262144
net.core.rmem_max=536870912
net.core.wmem_default=262144
net.core.wmem_max=536870912
net.ipv4.tcp_rmem=4096 87380 536870912
net.ipv4.tcp_wmem=4096 65536 536870912

# File Descriptors
fs.file-max=2097152
fs.inotify.max_user_watches=524288
EOF

# ===== XFCE WINDOW MANAGER OPTIMIZATION =====
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="activate_raise" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="enable_animations" type="bool" value="false"/>
    <property name="unredirect_overlays" type="bool" value="true"/>
    <property name="use_compositing" type="bool" value="true"/>
  </property>
</channel>
EOF

# ===== XFCE DESKTOP CONFIGURATION =====
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfdesktop" version="1.0">
  <property name="desktop" type="empty">
    <property name="show-thumbnails" type="bool" value="false"/>
    <property name="show-file-icons" type="bool" value="false"/>
    <property name="single-workspace-mode" type="bool" value="true"/>
  </property>
</channel>
EOF

# ===== XFCE PANEL CONFIGURATION =====
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

# ===== TigerVNC OPTIMIZATION =====
RUN mkdir -p /etc/tigervnc && \
    cat > /etc/tigervnc/vncserver-config-defaults << 'EOF'
localhost=no
SecurityTypes=None
IdleTimeout=0
MaxConnectionTime=0
MaxDisconnectionTime=0
MaxIdleTime=0
alwaysShared=1
dontDisconnect=1
FrameRate=60
EOF

# ===== USER SETUP =====
RUN useradd -m -s /bin/bash -G sudo,audio,video user && \
    echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/user/.config/google-chrome/Default && \
    cp /root/.config/google-chrome/Default/Preferences \
       /home/user/.config/google-chrome/Default/ 2>/dev/null || true && \
    chown -R user:user /home/user

# ===== SHARED MEMORY FIX =====
RUN echo "* soft memlock unlimited" >> /etc/security/limits.conf && \
    echo "* hard memlock unlimited" >> /etc/security/limits.conf

# ===== STARTUP SCRIPT =====
RUN cat > /usr/local/bin/start.sh << 'STARTSCRIPT'
#!/bin/bash
set -e

echo "==============================================="
echo "  🚀 Chrome Heavy Browsing Optimization Mode  "
echo "==============================================="

# Kernel tuning (best effort, mungkin gagal di container)
echo "⚙️  Optimizing system kernel..."
sysctl -p > /dev/null 2>&1 || true

echo "💾 Clearing page cache..."
sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# Bersihkan lock VNC lama jika ada
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

echo "🖥️  Starting VNC Server on :1 (port 5901)..."
vncserver \
    -localhost no \
    -SecurityTypes None \
    -geometry 1920x1080 \
    -depth 24 \
    -rfbport 5901 \
    --I-KNOW-THIS-IS-INSECURE :1

sleep 3

echo "🌐 Starting Google Chrome..."
export DISPLAY=:1

google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-breakpad \
    --disable-client-side-phishing-detection \
    --disable-default-apps \
    --disable-extensions \
    --disable-features=InterestFeedContentSuggestions,Translate \
    --disable-hang-monitor \
    --disable-metrics \
    --disable-sync \
    --enable-gpu \
    --enable-gpu-compositing \
    --enable-zero-copy \
    --enable-quic \
    --ignore-gpu-blocklist \
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
    -x509 -days 365 -nodes \
    -out /tmp/self.pem \
    -keyout /tmp/self.pem 2>/dev/null

echo "🌍 Starting noVNC WebSocket Proxy on port 6080..."
websockify -D \
    --web=/usr/share/novnc/ \
    --cert=/tmp/self.pem \
    --min-backlog=64 \
    6080 localhost:5901

echo ""
echo "==============================================="
echo "✅ SYSTEM READY!"
echo "==============================================="
echo "📍 noVNC URL : https://localhost:6080/vnc.html"
echo "📍 VNC Port  : 5901"
echo "📍 Browser   : Google Chrome (Optimized)"
echo "📍 Resolution: 1920x1080"
echo "==============================================="

# Keep container alive
tail -f /dev/null
STARTSCRIPT

RUN chmod +x /usr/local/bin/start.sh

# ===== CLEANUP =====
RUN apt clean && \
    apt autoclean && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===== INIT =====
RUN touch /root/.Xauthority

EXPOSE 5901
EXPOSE 6080

ENTRYPOINT ["/usr/local/bin/start.sh"]
