#!/usr/bin/env bash
set -euo pipefail

# ==== ROOT CHECK ====
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2; exit 1
fi

WORKINGDIR=$PWD
INSTALL_USER="${SUDO_USER:-$USER}"

echo "Current user: $INSTALL_USER"

echo
echo "Select CasparCG output consumer:"
echo "  1) Screen (HDMI/monitor)"
echo "  2) DeckLink / UltraStudio"
read -rp "Enter choice [1-2]: " choice

# some quality of life tools for debugging
apt install -y vim less

# set up the service account
useradd -r -m casparcg
usermod -aG video,audio casparcg

# Add current user to the casparcg group to make media file managemnt easier
usermod -aG casparcg $INSTALL_USER

# kill auto-updates and quiet motd
systemctl disable apt-daily.timer apt-daily-upgrade.timer
systemctl mask motd-news.timer

# copy the services that get installed for either option
cp casparcg-scanner.service /etc/systemd/system/
cp companion.service /etc/systemd/system/

# create the casparcg working directory:
mkdir -p /opt/casparcg

# get the installers for Casparcg.  This has to be somewhere that the 'apt' user can read them so lets make a temp folder
mkdir -p /opt/tmp
chmod 705 /opt/tmp
cd /opt/tmp
wget https://github.com/CasparCG/server/releases/download/v2.4.3-stable/casparcg-server-2.4_2.4.3.stable-noble1_amd64.deb
wget https://github.com/CasparCG/server/releases/download/v2.4.3-stable/casparcg-cef-117_117.2.5.gda4c36a+2-noble1.2_amd64.deb
wget https://github.com/CasparCG/media-scanner/releases/download/v1.3.4/casparcg-scanner_1.3.4-ubuntu1_amd64.deb

# Run all the installers
apt install -y ./*.deb

# go back where we came from
cd $WORKINGDIR


case "$choice" in
  1)
    echo "Configuring Screen consumer..."

    # Ensure the user has a user manager even without logins  # Chatgpt add
    sudo loginctl enable-linger casparcg

    # install x server, unclutter (to hide the mouse)
    apt update
    apt install -y xserver-xorg xinit x11-xserver-utils mesa-utils openbox unclutter
    # these supply libraries that the version working on a full desktop ubuntu were 
    #     using that this installation was not
    apt install -y \
      dconf-gsettings-backend \
      gvfs-daemons gvfs-libs \
      libcanberra-gtk3-0 libcanberra-gtk3-module libcanberra0 \
      libltdl7 \
      libnss3 \
      libpipewire-0.3-0 pipewire \
      libspa-0.2-modules \
      libsecret-1-0 \
      libsqlite3-0 \
      libtdb1 \
      libc-bin

    # prepare x settings for casparcg user:
    mkdir -p /home/casparcg/.xinitrc.d
    chmod 770 /home/casparcg/.xinitrc.d
    chown casparcg:casparcg /home/casparcg/.xinitrc.d
    cp xinitrc /home/casparcg/.xinitrc
    chmod 755 /home/casparcg/.xinitrc
    chown casparcg:casparcg /home/casparcg/.xinitrc

    # Xwrapper.config allows us to run from non-attached console (IE a service or ssh session)
    cp Xwrapper.config /etc/X11/Xwrapper.config

    # Copy the casparcg-x service and config files into place
    cp casparcg-x.service /etc/systemd/system/casparcg.service 
    cp casparcg-x.config  /opt/casparcg/casparcg.config 

    ;;
  2)
    echo "Configuring DeckLink consumer..."

    # install build tools and dkms:
    apt install -y build-essential linux-headers-$(uname -r) dkms

    read -rp Please provide Blackmagic Designs Desktop Video Linux Download URL: url

    wget $url
    
    mv Blackmagic_Desktop_Video_Linux* BMD_DVL.tar.gz
    tar -xf BMD_DVL.tar.gz

    mv ./Blackmagic*/deb/x86_64/desktopvideo_*.deb /opt/tmp/BMD_DVL.deb

    apt install -y /opt/tmp/BMD_DVL.deb

    # Copy the casparcg-decklink service and config files into place
    cp casparcg-decklink.service /etc/systemd/system/casparcg.service
    cp casparcg-decklink.config  /opt/casparcg/casparcg.config 
    ;;
  *)
    echo "Invalid choice, Exiting"
    exit
    ;;
esac

# clean up the deb installer folder
rm -rf /opt/tmp

# Create and set the group write permission on the media dir
#     so that the current user can manage media without sudo:
mkdir -p /opt/casparcg/media
chmod g+w /opt/casparcg/media

# set the ownership of the Casparcg folder to the service account
chown -R casparcg:casparcg /opt/casparcg

############## Companion ################
useradd -r companion
wget https://s4.bitfocus.io/builds/companion/companion-linux-x64-4.1.3+8475-stable-02928d8be8.tar.gz
tar -xzvf companion-linux-x64-4.1.3+8475-stable-02928d8be8.tar.gz 
mv companion-x64 /opt/companion

# Set up udev rules to allow companion to use streamdecks/other hardware
cp /opt/companion/50-companion-headless.rules /etc/udev/rules.d/50-companion.rules
udevadm control --reload-rules

# Make companion service account owner of this folder
chown -R companion:companion /opt/companion


#start the new services
systemctl enable --now companion.service
systemctl enable --now casparcg-scanner.service
systemctl enable --now casparcg.service
