#!/usr/bin/env fish

set current (hyprctl getoption input:kb_variant | string match -r 'str: (.*)' | tail -1)

# Toggle between QWERTY and Colemak
if test "$current" = colemak
    hyprctl keyword input:kb_variant ""
    notify-send "Keyboard Layout" "Switched to QWERTY" -t 1500
else
    hyprctl keyword input:kb_variant colemak
    notify-send "Keyboard Layout" "Switched to Colemak" -t 1500
end
