# VideoServer
An easy-to-deploy configuration of casparcg and bitfocus companion to create a simple but highly reliable video playback server.

# Installation
I installed this on a minimal install of ubuntu server (with ssh).  If you have a GPU you might want to enable 3rd party drivers to get the nvidia or AMD drivers, but I don't have a GPU in my system.  I am throughly testing the install process for the x-server version of this, I don't have any decklinks floating around to test the decklink version.

After installing the minimal server instance, I ssh into the box and install git, clone this repo and `chmod +x install_videoserver.sh` 

# Functionality
The initial goal of the script was to install an absolutely minimal, stripped out, X window manager and configure it to run casparcg on boot.  No gnome, no KDE, no other desktop applications, just casparcg.  In the background it runs casparcg-scanner and bitfocus companion for stream-deck control.  If your streamdeck is attached before you install this, you will either need to re-plug it or reboot.  I added decklink functionality to try to make it more professional but the older machine I acquired for the proof-of-concept only had USB ports and SFF PCIE slots.  UltraStudio USB-models are not compatible with linux.  I am watching Ebay for a decklink mini (monitor or duo 2).

The media folder for casparcg is `/opt/casparcg/media`.  This will give your active user write permission to that directory for copying files over (SSH, SCP, USB, etc..)

Companion is running on port 8080 since casparcg-scanner uses port 8000

# Why
My church had a video server that rendered backgrounds and was controlled by the lighting operator via stream-deck at one campus.  This made scene transisitions seamless between lights and background graphics.  I realized I could make something professional and very inexpensive using casparcg.  I have the linux know-how to come up with a very robust solution that shouldn't get popups and will recover from crashes. ChatGPT and the CCG forumns can help fill in the gaps.  I remember trying to figure stuff like this out as a high-schooler.  Hopefully this helps future Mes!

### Do not expose this to the internet ###