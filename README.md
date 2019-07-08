# Geniatech TV Tuner RE


## Introduction

The purpose of this repository is to document the protocol used by the
Geniatech A681/PT681 ATSC/ClearQAM USB TV tuner dongles.

My reasons for targeting these devices:

 - They're relatively inexpensive compared to other ATSC tuners (less
   than $30 in most cases), especially the subset that is supported by
   the mainline Linux kernel.
 - They seem to be white-label products, branded and sold by several
   different companies, making them fairly easy to acquire from a number
   of retailers (AliExpress, Amazon, etc.).
 - Unlike most TV tuner devices, they don't require the host PC to
   upload any proprietary firmware to the device in order to function,
   making them suitable for use in situations where software freedom is
   a concern.
 - The proprietary firmware that exists on the device is in an EEPROM
   that can be re-flashed by the host without any special hardware
   tools, making it easier for end users to potentially replace it with
   a FOSS alternative.


## Reverse engineering notes

Hardware and protocol notes can be found in [Notes.md](./Notes.md).
