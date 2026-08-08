#!/bin/bash
# PØLYBĪUS launcher for R36 S / R36 Ultra (ARM Linux handhelds).
#
# Place this whole aarch64 bundle folder onto the SD card under your frontend's
# "ports"/apps directory (e.g. /roms/ports/polybius/ on ArkOS/JELOS/MuOS), then
# launch it from the Ports menu. Adjust the path below to where you copied it.
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1
# The executable is named "polybius" inside the bundle.
export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
./polybius
