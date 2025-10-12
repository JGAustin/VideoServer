#!/usr/bin/env bash
unclutter -idle 0 -root &
xset -dpms
xset s off
exec /usr/bin/casparcg-server-2.4 /opt/casparcg/casparcg.conf