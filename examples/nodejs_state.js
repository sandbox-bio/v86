#!/usr/bin/env node
"use strict";

var fs = require("fs");
var V86Starter = require("../build/libv86.js").V86Starter;

function readfile(path)
{
    return new Uint8Array(fs.readFileSync(path)).buffer;
}

console.log("Use F2 to save the state and F3 to restore.");

var bios = readfile(__dirname + "/../bios/seabios.bin");
var linux = readfile(__dirname + "/../images/linux4.iso");

process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.setEncoding("utf8");

console.log("Now booting, please stand by ...");

var emulator = new V86Starter({
    bios: { buffer: bios },
    cdrom: { buffer: linux },
    autostart: true,
});

emulator.add_listener("serial0-output-byte", function(byte)
{
    var chr = String.fromCharCode(byte);
    if(chr <= "~")
    {
        process.stdout.write(chr);
    }
});

var state;

process.stdin.on("data", async function(c)
{
    if(c === "\u0003")
    {
        // ctrl c
        emulator.stop();
        process.stdin.pause();
    }
    else if(c === "\x1b\x4f\x51")
    {
        // f2
        state = await emulator.save_state();
        console.log("--- Saved ---");
    }
    else if(c === "\x1b\x4f\x52")
    {
        // f3
        if(state)
        {
            console.log("--- Restored ---");
            await emulator.restore_state(state);
        }
    }
    else
    {
        emulator.serial0_send(c);
    }
});
