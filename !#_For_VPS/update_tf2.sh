#!/bin/bash
BINDIR=$(dirname "$(readlink -fn "$0")")
$BINDIR/steamcmd.sh +force_install_dir /home/steam/tf2 +login anonymous +app_update 232250 +quit
