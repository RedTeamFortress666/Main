#!/bin/bash
# PØLYBĪUS — Ports launcher for R36S-class RK3326 handhelds
# (ArkOS / ROCKNIX / JELOS / AmberELEC and other RG351/RK3326 firmwares).
#
# INSTALL: copy this file AND the "polybius" folder next to it into your
# firmware's ports directory (usually /roms/ports/ or /roms2/ports/), then pick
# "Polybius" from the Ports menu in EmulationStation.
#
# This is a Flutter *GTK/X11* desktop app, not an SDL port, so the launcher
# starts a minimal X server for it. See polybius/README.txt for caveats.

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/polybius"
LOG="$DIR/polybius.log"

# Everything below is logged next to the launcher for troubleshooting.
exec > "$LOG" 2>&1
echo "== PØLYBĪUS launch $(date) =="
echo "launcher dir: $DIR"

cd "$APP" 2>/dev/null || { echo "ERROR: app folder '$APP' not found"; exit 1; }

export LD_LIBRARY_PATH="$APP/lib:$LD_LIBRARY_PATH"
export GDK_BACKEND=x11
# Some RK3326 Mali stacks are GLES-only; let GTK/Flutter fall back if desktop GL
# is unavailable. (Harmless where unused.)
export LIBGL_ALWAYS_SOFTWARE=${LIBGL_ALWAYS_SOFTWARE:-0}

# Map the handheld's gamepad to the keys the game understands (d-pad -> arrows,
# A -> space, B -> escape, Start -> enter). ArkOS/ROCKNIX ship gptokeyb; if it
# is present we run it in the background against polybius.gptk. The game also
# reads /dev/input gamepads natively, so this is best-effort assistance for
# menu navigation.
GPTOKEYB="$(command -v gptokeyb 2>/dev/null)"
[ -z "$GPTOKEYB" ] && [ -x /roms/ports/PortMaster/gptokeyb ] && GPTOKEYB=/roms/ports/PortMaster/gptokeyb
GPTK_PID=""
if [ -n "$GPTOKEYB" ] && [ -f "$APP/polybius.gptk" ]; then
  echo "using gptokeyb: $GPTOKEYB"
  "$GPTOKEYB" "polybius" -c "$APP/polybius.gptk" &
  GPTK_PID=$!
fi

# Launch. If an X server is already up (some firmwares), use it; otherwise start
# our own with xinit on vt1.
if [ -n "$DISPLAY" ] && command -v xset >/dev/null 2>&1 && xset q >/dev/null 2>&1; then
  echo "using existing X display $DISPLAY"
  ./polybius
elif command -v xinit >/dev/null 2>&1; then
  echo "starting X via xinit"
  xinit ./polybius -- :0 -nolisten tcp vt1
else
  echo "WARNING: no X server / xinit found; trying direct launch (likely to fail on GTK)"
  ./polybius
fi
RC=$?

[ -n "$GPTK_PID" ] && kill "$GPTK_PID" 2>/dev/null
echo "== exit code $RC $(date) =="
exit $RC
