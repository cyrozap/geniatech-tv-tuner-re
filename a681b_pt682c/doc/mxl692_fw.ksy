meta:
  id: mxl692_fw
  file-extension: fw
  endian: be
  title: MaxLinear MxL692 Firmware Image
  license: CC0-1.0
seq:
  - id: header
    type: header
  - id: body
    size: header.body_len
    type: body
types:
  header:
    seq:
      - id: magic
        contents: [0x4d, 0x31, 0x10, 0x02, 0x40, 0x00, 0x00, 0x80]
      - id: body_len
        type: b24
      - id: checksum
        type: u1
      - id: padding
        size: 4
  body:
    seq:
      - id: segment
        type: segment
        repeat: eos
  segment:
    seq:
      - id: padding
        size: 4 - (_io.pos & 3)
        if: _io.pos & 3 != 0
      - id: magic
        contents: [0x53]
      - id: len
        type: b24
      - id: addr
        type: u4
      - id: data
        size: len
