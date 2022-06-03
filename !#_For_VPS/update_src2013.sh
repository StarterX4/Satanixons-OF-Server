#!/bin/bash
BINDIR=$(dirname "$(readlink -fn "$0")")
$BINDIR/steamcmd.sh +force_install_dir /home/steam/sdk2013 +login anonymous +app_update 244310 +quit
