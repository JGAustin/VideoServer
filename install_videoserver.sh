# ==== ROOT CHECK ====
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2; exit 1
fi

WORKINGDIR=$PWD

# install x server, unclutter (to hide the mouse) and some tools I used in the debug process
apt install -y xserver-xorg xinit x11-xserver-utils mesa-utils openbox unclutter vim

useradd -r -m casparcg
usermod -aG video,audio casparcg
# Add current user to the casparcg group to make media file managemnt easier
usermod -aG casparcg $USER

# prepare x settings for casparcg user:
mkdir /home/casparcg/.xinitrc.d
chmod 770 /home/casparcg/.xinitrc.d
chown casparcg:casparcg /home/casparcg/.xinitrc.d
cp xinitrc /home/casparcg/.xinitrc
chmod 755 /home/casparcg/.xinitrc
chown casparcg:casparcg /home/casparcg/.xinitrc

# kill auto-updates and quiet motd
systemctl disable apt-daily.timer apt-daily-upgrade.timer
systemctl mask motd-news.timer

#disable screen blanking
sudo -u casparcg bash -c 'echo "xset -dpms; xset s off" >> ~/.xinitrc'

mkdir /opt/casparcg
cp casparcg.conf /opt/casparcg
chown -R casparcg:casparcg /opt/casparcg

# Xwrapper.config allows us to run from non-attached console (IE a service or ssh session)
cp Xwrapper.config /etc/X11/Xwrapper.config

# Copy the services into place
cp casparcg.service /etc/systemd/system/
cp casparcg-scanner.service /etc/systemd/system/
cp companion.service /etc/systemd/system/

# get the installers for Casparcg.  This has to be somewhere that the 'apt' user can read them so lets make a temp folder
mkdir /opt/tmp
chmod 705 /opt/tmp
cd /opt/tmp
wget https://github.com/CasparCG/server/releases/download/v2.4.3-stable/casparcg-server-2.4_2.4.3.stable-noble1_amd64.deb
wget https://github.com/CasparCG/server/releases/download/v2.4.3-stable/casparcg-cef-117_117.2.5.gda4c36a+2-noble1.2_amd64.deb
wget https://github.com/CasparCG/media-scanner/releases/download/v1.3.4/casparcg-scanner_1.3.4-ubuntu1_amd64.deb

# Run all the installers
apt install ./*.deb

# go back where we came from and clean up
cd $WORKINGDIR
rm -rf /opt/tmp

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
