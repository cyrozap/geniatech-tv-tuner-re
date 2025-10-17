#!/bin/sh
# SPDX-License-Identifier: 0BSD

# Copyright (C) 2025 by Forest Crossman <cyrozap@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for
# any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

set -euo pipefail

TMPDIR="$(mktemp -p /tmp -d extract.XXXXXXXXXX)"
ZIPFILE="${TMPDIR}/windows_driver_20240605.zip"
DRIVER='windows driver 20240605/x64/Drivers/cyDtv.Sys'
FIRMWARE="${TMPDIR}/dvb-demod-mxl692.fw"

# Download and extract the firmware image
curl -o "${ZIPFILE}" 'https://web.archive.org/web/20250624041039if_/https://file.geniatech.com/mygica/Driver/windows_driver_20240605.zip'
unzip "${ZIPFILE}" "${DRIVER}" -d "${TMPDIR}"
dd if="${TMPDIR}/${DRIVER}" of="${FIRMWARE}" bs=1 skip=1281456 count=43997

# Check the firmware hash
sha256sum -c <<EOF
8f77d5cb0de9111ed63c113cb2fd54a63e07a30040ae0b562cb025ab9c4e600d  ${FIRMWARE}
EOF

# Install the firmware image
sudo install -Dm644 "${FIRMWARE}" /lib/firmware/

# Cleanup
rm -r "${TMPDIR}"
