#!/bin/bash

target=$1
osascript << EOF
if application "Adium" is running then
	-- Force application to quit
	tell application "Adium" to quit
	-- Wait until it quits
	repeat
		if application "Adium" is not running then exit repeat
		delay 1
	end repeat
end if
EOF

open $target
