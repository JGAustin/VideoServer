#!/usr/bin/env bash
xset -dpms
xset s off

# the /dev/null piped to stdin fixes the hang on startup that I was experiencing
exec /usr/bin/casparcg-server-2.4 /opt/casparcg/casparcg.config < /dev/null