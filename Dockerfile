FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install semua package yang diperlukan
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    init \
    systemd \
    snapd \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    openssl \
    && apt update -y && apt install -y \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    && apt install -y software-properties-common

# Install Firefox dari PPA Mozilla
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt update -y && apt install -y firefox && \
    apt update -y && apt install -y xubuntu-icon-theme

# ============================================================
# BUAT USER TERBATAS
# ============================================================
RUN useradd -m -s /usr/sbin/nologin restricteduser && \
    echo "restricteduser:password123" | chpasswd

# ============================================================
# HAPUS TERMINAL & APLIKASI BERBAHAYA (saat build masih pakai sh)
# ============================================================
RUN apt remove -y --purge \
    xfce4-terminal \
    xterm \
    gnome-terminal \
    konsole \
    lxterminal \
    mousepad \
    gedit 2>/dev/null || true

RUN rm -f \
    /usr/share/applications/xfce4-terminal.desktop \
    /usr/share/applications/xterm.desktop \
    /usr/share/applications/exo-terminal-emulator.desktop \
    /usr/share/applications/xfce4-appfinder.desktop \
    /usr/share/applications/thunar.desktop \
    /usr/share/applications/thunar-bulk-rename.desktop \
    /usr/share/applications/mousepad.desktop \
    /usr/share/applications/vim.desktop \
    /usr/share/applications/nano.desktop 2>/dev/null || true

# ============================================================
# KONFIGURASI XFCE UNTUK restricteduser
# ============================================================
RUN mkdir -p /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml

# Nonaktifkan desktop right-click menu
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

# Nonaktifkan semua keyboard shortcut XFCE
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

# Nonaktifkan fitur window manager berbahaya
RUN cat > /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="easy_click" type="string" value="None"/>
    <property name="mousewheel_rollup" type="bool" value="false"/>
  </property>
</channel>
EOF

# Panel XFCE minimal (hanya clock, tanpa launcher)
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

# Autostart hanya Firefox
RUN mkdir -p /home/restricteduser/.config/autostart && \
    cat > /home/restricteduser/.config/autostart/firefox.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox --no-first-run --disable-restore-session-state
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Fix ownership
RUN chown -R restricteduser:restricteduser /home/restricteduser/

# ============================================================
# BUAT STARTUP SCRIPT
# Blokir shell & command berbahaya dilakukan di SINI (runtime)
# bukan saat build, agar Docker build tidak error
# ============================================================
RUN cat > /start.sh << 'STARTSCRIPT'
#!/bin/bash

echo "[*] Mengunci binary berbahaya..."

# Daftar binary yang akan diblokir
BLOCK_LIST=(
    /bin/bash
    /bin/sh
    /bin/dash
    /bin/rbash
    /usr/bin/bash
    /usr/bin/sh
    /usr/bin/dash
    /usr/bin/zsh
    /usr/bin/fish
    /usr/bin/ksh
    /usr/bin/tcsh
    /usr/bin/csh
    /usr/bin/perl
    /usr/bin/python3
    /usr/bin/python3.10
    /usr/bin/python
    /usr/bin/ruby
    /usr/bin/php
    /usr/bin/lua
    /usr/bin/node
    /usr/bin/nodejs
    /usr/bin/npm
    /usr/bin/pip
    /usr/bin/pip3
    /usr/bin/vim
    /usr/bin/vi
    /usr/bin/nano
    /usr/bin/emacs
    /usr/bin/mousepad
    /usr/bin/gedit
    /usr/bin/xterm
    /usr/bin/xfce4-terminal
    /usr/bin/gnome-terminal
    /usr/bin/xfce4-appfinder
    /usr/bin/xfrun4
    /usr/bin/thunar
    /usr/bin/nautilus
    /usr/bin/pcmanfm
    /usr/bin/wget
    /usr/bin/curl
    /usr/bin/git
    /usr/bin/ssh
    /usr/bin/scp
    /usr/bin/sftp
    /usr/bin/ftp
    /usr/bin/telnet
    /usr/bin/nc
    /usr/bin/netcat
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
    /usr/bin/userdel
    /usr/bin/chsh
    /usr/bin/chpasswd
    /usr/bin/adduser
    /usr/bin/deluser
    /usr/bin/visudo
    /usr/bin/crontab
    /usr/bin/at
    /usr/bin/chmod
    /usr/bin/chown
    /usr/bin/chroot
    /usr/bin/mount
    /usr/bin/dd
    /usr/bin/mkfs
    /usr/bin/fdisk
    /usr/bin/kill
    /usr/bin/killall
    /usr/bin/pkill
    /usr/bin/top
    /usr/bin/htop
    /usr/bin/strace
    /usr/bin/ltrace
    /usr/bin/gdb
    /usr/bin/find
    /usr/bin/locate
    /usr/bin/base64
    /usr/bin/xxd
    /usr/bin/hexdump
    /usr/bin/strings
    /usr/bin/zip
    /usr/bin/unzip
    /usr/bin/tar
    /usr/bin/gzip
    /usr/bin/xz
    /usr/bin/rsync
    /usr/bin/nmcli
    /usr/bin/ifconfig
    /usr/sbin/useradd
    /usr/sbin/usermod
    /usr/sbin/userdel
    /usr/sbin/chpasswd
    /usr/sbin/visudo
    /sbin/mount
    /sbin/fdisk
)

for binary in "${BLOCK_LIST[@]}"; do
    if [ -f "$binary" ]; then
        chmod 000 "$binary"
        echo "  [BLOCKED] $binary"
    fi
done

echo "[*] Binary berbahaya berhasil dikunci"

# ============================================================
# Setup VNC untuk restricteduser
# ============================================================
echo "[*] Setup VNC..."
mkdir -p /home/restricteduser/.vnc

cat > /home/restricteduser/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XSTARTUP

chmod +x /home/restricteduser/.vnc/xstartup
chown -R restricteduser:restricteduser /home/restricteduser/

# Jalankan VNC sebagai restricteduser
echo "[*] Menjalankan VNC server..."
su restricteduser -s /bin/bash -c \
    "vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE"

# Generate SSL
echo "[*] Generate SSL certificate..."
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes \
    -out /self.pem -keyout /self.pem 2>/dev/null

# Jalankan websockify
echo "[*] Menjalankan noVNC websockify..."
websockify -D \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    6080 localhost:5901

echo "[*] Semua service berjalan!"
echo "[*] Akses via browser: http://localhost:6080"

tail -f /dev/null
STARTSCRIPT

RUN chmod +x /start.sh

EXPOSE 5901
EXPOSE 6080

CMD ["/start.sh"]
