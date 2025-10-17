#!/usr/bin/env python3
# SPDX-License-Identifier: 0BSD

# Copyright (C) 2019 by Forest Crossman <cyrozap@gmail.com>
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


import time

import usb

if __name__ == "__main__":
    dev = usb.core.find(idVendor=0x1f4d, idProduct=0xa681)
    if dev is None:
        raise ValueError('Device not found or insufficient permissions.')

    #assert(dev.write(1, bytes.fromhex('de00'), 1000) == 2)
    #assert(dev.write(1, bytes.fromhex('0e8000'), 1000) == 3)
    #assert(bytes(dev.read(0x81, 1, 1000))[0] == 1)
    #assert(dev.write(1, bytes.fromhex('0e8001'), 1000) == 3)
    #assert(bytes(dev.read(0x81, 1, 1000))[0] == 1)

    # Continuously check for IR remote key presses.
    while True:
        assert(dev.write(1, bytes([0x10]), 100) == 1)
        ir_data = bytes(dev.read(0x81, 2, 100)).hex()
        if ir_data != 'ffff':
            print(ir_data)
        time.sleep(0.05)
