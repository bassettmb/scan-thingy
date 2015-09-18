#! env bash
masscan "$SCAN_SUBNET" -p "$SCAN_PORTS" --rate "$SCAN_RATE" -oJ '/dev/stdout'
