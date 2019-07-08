# Protocol


## Commands


### I2C Write


#### Overview

Command format:

 - 1B: Command byte (`0x08`)
 - 1B: 7-bit I2C device address.
 - 1B: Length of bytes to write.
 - N: The bytes to write.

Response format:

 - 1B: Always `0x08`. Presumably it will be something different if the
   command fails, but I've never seen that happen.

To use this command, make a USB bulk write with the command, then a bulk
read to read the 1-byte response.


#### Detailed description

This command is used to set registers in the demodulator and tuner ICs.
For example, to write `0x00` to register address `0xFF` in the tuner
(triggering a soft reset), you would send the following:

```
08 60 02 ff 00
```

Where `0x08` is the command (I2C Write), `0x60` is the 7-bit address of
the tuner IC, `0x02` is the number of data bytes in the I2C Write
transaction (i.e., everything following that length byte will be sent
over the wire), `0xff` is the address of the register to write to, and
`0x00` is the data to write to that register.

Similarly, this command is also used to make register writes to the
demodulator:

```
08 18 02 00 50
```

This will write `0x50` into register `0x00` of the main bank of
registers (I2C device `0x18`) of the demodulator, which has two register
banks (`MAIN`, I2C address `0x18`; and `USR`, I2C address `0x10`).

In theory, this command could be used to make arbitrary other I2C writes
with different data lengths, but since we only need to communicate with
the tuner and demodulator, and they use the same "1B address, 1B value"
register write sequence, in practice all the I2C Write commands we'll
ever send will be of the form `08 XX 02 YY ZZ`.


### I2C Read


#### Overview

Command format:

 - 1B: Command byte (`0x09`)
 - 1B: Length of bytes to write.
 - 1B: Length of bytes to read.
 - 1B: 7-bit I2C device address.
 - N: The bytes to write.

Response format:

 - 1B: Always `0x08`. Presumably it will be something different if the
   command fails, but I've never seen that happen.
 - N: The bytes read.

To use this command, make a USB bulk write with the command, then a bulk
read to get the status byte and the data returned from the I2C Read
transaction.


#### Detailed description

This command is used to read registers in the demodulator and tuner ICs.
The generic command and response formats are the same for both the tuner
and the demodulator, but because the two devices use slightly different
formats for reads over the wire, you'll need to pay attention to that
when accessing the tuner vs. the demodulator.

For example, to read register `0xc4` in the main bank of the
demodulator, the command is as follows:

```
09 01 01 18 c4
```

Where `0x09` is the command (I2C Read), the first `0x01` is the number
of bytes to write (since the I2C Read actually requires a combined write
and read), the second `0x01` is the number of bytes to read, `0x18` is
the I2C address of the device to read from, and `0xc4` is the address of
the register you want to read.

The response to that looks like this:

```
08 30
```

Where `0x08` is the status byte and `0x30` is the value that was just
read from register `0xc4`.

By contrast, to read register `0x2b` in the tuner, you would send this:

```
09 02 01 60 fb 2b
```

Note the `0x02` for the number of bytes written, and that extra `0xfb`
before the register address. For some reason, the tuner requires that
`0xfb` byte as the first byte of its register read sequence, so it gets
included there in the final read command.

The response is the same format as it is when reading from the
demodulator:

```
08 07
```

Where `0x08` is the status byte and `0x07` is the value that was just
read from register `0x2b`.

So, as with the I2C Write command, while the I2C Read command is
flexible in theory, in practice it is only used in two ways:
`09 01 01 XX YY` to read from the demodulator, and `09 02 01 XX fb YY`
to read from the tuner.
