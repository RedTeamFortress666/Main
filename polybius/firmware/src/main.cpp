#include "polybius/board_ui.h"
#include "polybius/serial_shell.h"

#include <Arduino.h>

using polybius::AppState;
using polybius::BoardUi;
using polybius::SerialShell;

static AppState gState;
static BoardUi* gUi = nullptr;
static SerialShell gShell;
static bool gDirty = true;

void setup() {
  gUi = polybius::createBoardUi();
  gUi->begin();
  gShell.begin(gState);
  gState.status = "unlock 000000";
  gDirty = true;
}

void loop() {
  if (gShell.poll(gState)) gDirty = true;
  if (gUi && gUi->poll(gState)) gDirty = true;
  if (gDirty && gUi) {
    gUi->draw(gState);
    gDirty = false;
  }
  delay(10);
}
