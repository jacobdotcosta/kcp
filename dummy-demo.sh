#!/usr/bin/env bash

. play-demo.sh

DEMO_PROMPT=">$ "

TYPE_SPEED=15
NO_WAIT=true
p "Scenario 1: Steps executed automatically as NO_WAIT=true"
pe "echo printing and executing automatically a \"<cmd>\""

NO_WAIT=true
TYPE_SPEED=7
p "Scenario 2: Steps executed automatically but slowing the display of the text"
pe "echo printing and executing automatically a \"<cmd>\""

p "Scenario 3: Steps executed manually as NO_WAIT=false BUT it is here needed that the user is pressing <ENTER> key"
NO_WAIT=false
pe "echo printing and executing a \"<cmd>\" after <ENTER> key pressed"

clear