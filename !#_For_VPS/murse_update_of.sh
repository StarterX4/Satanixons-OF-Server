#!/bin/bash
BINDIR=$(dirname "$(readlink -fn "$0")")
$BINDIR/murse upgrade sdk2013/open_fortress -u https://toast.openfortress.fun/toast/
