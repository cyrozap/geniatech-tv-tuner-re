#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 capture_file.pcap"
	exit 1
fi

tshark -r "$1" -T fields -e usb.capdata 'usb.endpoint_address.number == 1 && usb.data_len > 0'
