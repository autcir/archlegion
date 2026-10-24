#!/usr/bin/env bash
# Disable xfwm4 compositing (picom handles it instead).
xfconf-query -c xfwm4 -p /general/use_compositing -s false
