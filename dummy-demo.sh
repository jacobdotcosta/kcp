#!/usr/bin/env bash

. play-demo.sh

DEMO_PROMPT=">$ "

TYPE_SPEED=15
NO_WAIT=true
p "Scenario 1: Step executed automatically as NO_WAIT=true"
pe "echo printing a \"<cmd>\""

p "Scenario 2: Step executed automatically but slowing the display of the text"
TYPE_SPEED=7
pe "echo printing a \"<cmd>\""

TYPE_SPEED=15
p "Scenario 3: Step executed manually as NO_WAIT=false BUT it is here needed that the user is pressing <ENTER> key"
NO_WAIT=false
pe "echo printing a \"<cmd>\" after \"<ENTER>\" key pressed"

clear