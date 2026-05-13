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
RUN add-apt-repository ppa:mozillateam/ppa -y
RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
RUN apt update -y && apt install -y firefox
RUN apt update -y && apt install -y xubuntu-icon-theme

# ============================================================
# BUAT USER TERBATAS (bukan root)
# ============================================================
RUN useradd -m -s /usr/sbin/nologin restricteduser && \
    echo "restricteduser:password123" | chpasswd

# ============================================================
# BLOKIR SEMUA TERMINAL & SHELL
# ============================================================

# Hapus atau blokir semua emulator terminal dari XFCE
RUN apt remove -y xfce4-terminal xterm gnome-terminal konsole lxterminal \
    rxvt rxvt-unicode aterm eterm 2>/dev/null || true

# Ganti shell dengan nologin agar tidak bisa login shell
RUN chsh -s /usr/sbin/nologin restricteduser

# Blokir binary shell dan terminal dengan chmod 000
RUN chmod 000 /bin/bash || true
RUN chmod 000 /bin/sh || true
RUN chmod 000 /bin/dash || true
RUN chmod 000 /usr/bin/bash || true
RUN chmod 000 /usr/bin/sh || true
RUN chmod 000 /usr/bin/zsh || true
RUN chmod 000 /usr/bin/fish || true
RUN chmod 000 /usr/bin/ksh || true
RUN chmod 000 /usr/bin/tcsh || true
RUN chmod 000 /usr/bin/csh || true

# Blokir command berbahaya / terminal apps
RUN for cmd in \
    xterm \
    xfce4-terminal \
    gnome-terminal \
    konsole \
    lxterminal \
    xfrun4 \
    xfce4-appfinder \
    vim \
    vi \
    nano \
    emacs \
    gedit \
    mousepad \
    leafpad \
    kate \
    su \
    sudo \
    passwd \
    useradd \
    usermod \
    userdel \
    chsh \
    chpasswd \
    adduser \
    deluser \
    visudo \
    crontab \
    at \
    wget \
    curl \
    git \
    ssh \
    scp \
    sftp \
    ftp \
    telnet \
    nc \
    netcat \
    nmap \
    python3 \
    python \
    perl \
    ruby \
    php \
    lua \
    node \
    npm \
    pip \
    pip3 \
    apt \
    apt-get \
    dpkg \
    snap \
    flatpak \
    chmod \
    chown \
    chroot \
    mount \
    umount \
    dd \
    mkfs \
    fdisk \
    parted \
    kill \
    killall \
    pkill \
    ps \
    top \
    htop \
    id \
    whoami \
    env \
    printenv \
    strace \
    ltrace \
    gdb \
    objdump \
    strings \
    hexdump \
    xxd \
    base64 \
    find \
    locate \
    updatedb \
    xdg-open \
    xdg-user-dirs \
    dbus-launch \
    dbus-send \
    gdbus \
    gio \
    gvfs-open \
    nautilus \
    thunar \
    pcmanfm \
    nemo \
    zip \
    unzip \
    tar \
    gzip \
    gunzip \
    bzip2 \
    bunzip2 \
    xz \
    7z \
    rar \
    unrar \
    rsync \
    smbclient \
    nmcli \
    ifconfig \
    ip \
    route \
    iptables \
    ufw \
    firejail \
    ; do \
    path=$(which $cmd 2>/dev/null); \
    if [ -n "$path" ]; then chmod 000 "$path"; fi; \
    done

# ============================================================
# KUNCI FILE MANAGER DAN APPLICATION FINDER XFCE
# ============================================================
RUN chmod 000 /usr/bin/thunar || true
RUN chmod 000 /usr/bin/xfce4-appfinder || true
RUN chmod 000 /usr/bin/xfrun4 || true

# ============================================================
# HAPUS MENU ENTRY TERMINAL DI XFCE
# ============================================================
RUN rm -f /usr/share/applications/xfce4-terminal.desktop || true
RUN rm -f /usr/share/applications/xterm.desktop || true
RUN rm -f /usr/share/applications/exo-terminal-emulator.desktop || true
RUN rm -f /usr/share/applications/xfce4-appfinder.desktop || true
RUN rm -f /usr/share/applications/thunar.desktop || true
RUN rm -f /usr/share/applications/thunar-bulk-rename.desktop || true
RUN rm -f /usr/share/applications/mousepad.desktop || true

# ============================================================
# KONFIGURASI XFCE - NONAKTIFKAN RIGHT CLICK MENU & KEYBOARD SHORTCUT
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

# Konfigurasi XFWM4 - nonaktifkan fitur window management berbahaya
RUN cat > /home/restricteduser/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="easy_click" type="string" value="None"/>
    <property name="mousewheel_rollup" type="bool" value="false"/>
  </property>
</channel>
EOF

# ============================================================
# NONAKTIFKAN PANEL XFCE (agar tidak ada launcher terminal)
# ============================================================
RUN mkdir -p /home/restricteduser/.config/xfce4/panel
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
    <property name="plugin-1" type="string" value="applicationsmenu"/>
  </property>
</channel>
EOF

# ============================================================
# AUTOSTART - HANYA FIREFOX YANG BOLEH JALAN
# ============================================================
RUN mkdir -p /home/restricteduser/.config/autostart
RUN cat > /home/restricteduser/.config/autostart/firefox.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# ============================================================
# BUAT SCRIPT STARTUP
# ============================================================
RUN cat > /start.sh << 'STARTSCRIPT'
#!/bin/bash

# Jalankan sebagai root untuk setup VNC
mkdir -p /home/restricteduser/.vnc
echo "" | vncpasswd -f > /home/restricteduser/.vnc/passwd
chmod 600 /home/restricteduser/.vnc/passwd
chown -R restricteduser:restricteduser /home/restricteduser/

# Buat xstartup untuk VNC
cat > /home/restricteduser/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XSTARTUP

chmod +x /home/restricteduser/.vnc/xstartup
chown restricteduser:restricteduser /home/restricteduser/.vnc/xstartup

# Jalankan VNC sebagai restricteduser
su - restricteduser -s /bin/bash -c "vncserver :1 \
    -localhost no \
    -SecurityTypes None \
    -geometry 1024x768 \
    --I-KNOW-THIS-IS-INSECURE"

# Generate SSL cert
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes \
    -out /self.pem -keyout /self.pem

# Jalankan websockify
websockify -D \
    --web=/usr/share/novnc/ \
    --cert=/self.pem \
    6080 localhost:5901

tail -f /dev/null
STARTSCRIPT

RUN chmod +x /start.sh

# ============================================================
# PASTIKAN OWNERSHIP BENAR
# ============================================================
RUN chown -R restricteduser:restricteduser /home/restricteduser/

# ============================================================
# TAMBAHAN KEAMANAN - BLOKIR AKSES KE DIREKTORI SISTEM
# ============================================================
RUN chmod 000 /usr/bin/xdg-open || true
RUN chmod 000 /usr/lib/x86_64-linux-gnu/xfce4/exo-1/exo-helper-1 || true

EXPOSE 5901
EXPOSE 6080

CMD ["/start.sh"]
