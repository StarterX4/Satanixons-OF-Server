#!/bin/bash
BINDIR=$(dirname "$(readlink -fn "$0")")
$BINDIR/steamcmd.sh +force_install_dir /home/steam/zps +login anonymous +app_update 17505 validate +quit
