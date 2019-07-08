-- Geniatech A681/PT681
--
-- Copyright (C) 2019 Forest Crossman <cyrozap@gmail.com>
--
-- Based on the SysClk LWLA protocol dissector for Wireshark,
-- Copyright (C) 2014 Daniel Elstner <daniel.kitta@gmail.com>
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses/>.

-- Usage: wireshark -X lua_script:dissector.lua
--
-- It is not advisable to install this dissector globally, since
-- it will try to interpret the communication of any USB device
-- using the vendor-specific interface class.

-- Create custom protocol for the A681.
p_a681 = Proto("a681", "Geniatech A681/PT681 TV tuner protocol")

-- Control commands either read or write
local commands = {
    [0x08] = "I2C Write",
    [0x09] = "I2C Read",
    [0x10] = "IR Read",
    [0x36] = "Begin TS Dump?",
    [0x37] = "Tuner/Demod Hard Reset?"
}

local i2c_addresses = {
    [0x18] = "DMD_BANK_MAIN",
    [0x10] = "DMD_BANK_USR",
    [0x60] = "MxL603/MxL608"
}

-- Create the fields exhibited by the protocol.
p_a681.fields.command = ProtoField.uint8("a681.command", "Command", base.HEX, commands)
p_a681.fields.i2c_address = ProtoField.uint8("a681.command.i2c.address", "I2C Device Address", base.HEX, i2c_addresses)
p_a681.fields.i2c_register = ProtoField.uint8("a681.command.i2c.register", "I2C Register", base.HEX)
p_a681.fields.i2c_data = ProtoField.uint8("a681.command.i2c.data", "I2C Data", base.HEX)

p_a681.fields.status = ProtoField.uint8("a681.status", "A681 status", base.HEX)

p_a681.fields.unknown = ProtoField.bytes("a681.unknown", "Unidentified message data")

-- Referenced USB URB dissector fields.
local f_urb_type = Field.new("usb.urb_type")
local f_transfer_type = Field.new("usb.transfer_type")
local f_endpoint = Field.new("usb.endpoint_address.number")
local f_data_len = Field.new("usb.data_len")

-- Insert warning for undecoded leftover data.
local function warn_undecoded(tree, range)
    local item = tree:add(p_a681.fields.unknown, range)
    item:add_expert_info(PI_UNDECODED, PI_WARN, "Leftover data")
end

-- Dissect A681 control command messages.
local function dissect_control_command(buffer, pinfo, subtree)
    local command = buffer(0,1)

    subtree:add(p_a681.fields.command, command)

    -- Determine what protocol the A681 was set to
    if (command:uint() == 0x08) then
        subtree:add(p_a681.fields.i2c_address, buffer(1,1))
        -- buffer(2,1) is the number of bytes to write.
        subtree:add(p_a681.fields.i2c_register, buffer(3,1))
        subtree:add(p_a681.fields.i2c_data, buffer(4,1))
    elseif (command:uint() == 0x09) then
        -- buffer(1,1) is the number of bytes to write.
        -- buffer(2,1) is the number of bytes to read.
        local address = buffer(3,1)
        subtree:add(p_a681.fields.i2c_address, address)
        if (address:uint() == 0x60) then
            -- buffer(4,1) is 0xFB here, per the MxL603/MxL608 8-bit register read protocol.
            subtree:add(p_a681.fields.i2c_register, buffer(5,1))
        else
            subtree:add(p_a681.fields.i2c_register, buffer(4,1))
        end
    elseif (command:uint() == 0x10) then
    elseif (command:uint() == 0x36) then
        warn_undecoded(subtree, buffer(1))
    elseif (command:uint() == 0x37) then
        warn_undecoded(subtree, buffer(1))
    else
        warn_undecoded(subtree, buffer(1))
    end
end

-- Dissect A681 control response messages.
local function dissect_control_response(buffer, pinfo, subtree)
    local id = buffer(0,1)

    if (id:uint() == 0x08) then
        subtree:add(p_a681.fields.status, buffer(0,1))
        local data_len = tonumber(tostring(f_data_len()))
        if (data_len > 1) then
            subtree:add(p_a681.fields.i2c_data, buffer(1,1))
        end
    end
end

-- Main A681 dissector function.
function p_a681.dissector(buffer, pinfo, tree)
    local transfer_type = tonumber(tostring(f_transfer_type()))
    local endpoint = tonumber(tostring(f_endpoint()))
    local urb_type = tostring(f_urb_type())

    if ( (transfer_type == 3) and (endpoint == 0x01) ) then
        -- Bulk transfers
        local subtree = tree:add(p_a681, buffer(), "A681")

        -- We only care about the IN and OUT endpoints
        if (urb_type == "'S'") then
            -- Data out
            dissect_control_command(buffer, pinfo, subtree)
        elseif (urb_type == "'C'") then
            -- Data in
            dissect_control_response(buffer, pinfo, subtree)
        end
    else
        return 0
    end
end

function p_a681.init()
    local usb_product_dissectors = DissectorTable.get("usb.product")

    -- Dissection by vendor+product ID requires that Wireshark can get the
    -- the device descriptor.  Making a USB device available inside VirtualBox
    -- will make it inaccessible from Linux, so Wireshark cannot fetch the
    -- descriptor by itself.  However, it is sufficient if the VirtualBox
    -- guest requests the descriptor once while Wireshark is capturing.
    usb_product_dissectors:add(0x1f4da681, p_a681)

    -- Addendum: Protocol registration based on product ID does not always
    -- work as desired.  Register the protocol on the interface class instead.
    -- The downside is that it would be a bad idea to put this into the global
    -- configuration, so one has to make do with -X lua_script: for now.
    -- local usb_control_dissectors = DissectorTable.get("usb.control")

    -- For some reason the "unknown" class ID is sometimes 0xFF and sometimes
    -- 0xFFFF.  Register both to make it work all the time.
    -- usb_control_dissectors:add(0xFF, p_a681)
    -- usb_control_dissectors:add(0xFFFF, p_a681)
end
