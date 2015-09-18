#! env bash

set -eu

if (($UID)); then
  echo "$0: root permissions required"
  exit 1
fi

export SCAN_PROG="$0"
export SCAN_TIMESTAMP=$(date --iso-8601=seconds)

if (($?)); then
  exit 1
fi

export SCAN_SUBNET='10.66.0.0/14'
export SCAN_RATE='10000'
export SCAN_PORTS='80'
export SCAN_OUTDIR="$SCAN_TIMESTAMP-scan"
export SCAN_TIMEOUT='5'

bash scan.sh | sudo -E -n -u "#$SUDO_UID" bash probe.sh
