#!/usr/bin/env python3

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
