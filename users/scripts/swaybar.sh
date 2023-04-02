#!/usr/bin/env bash
# Change this according to your device
################
# Variables
################

# Date and time
date_and_week=$(date "+%Y/%m/%d (w%-V)")
current_time=$(date "+%H:%M")

audio_volume=$(pamixer --sink $(pactl list sinks short | grep RUNNING | awk '{print $1}') --get-volume)
audio_is_muted=$(pamixer --sink $(pactl list sinks short | grep RUNNING | awk '{print $1}') --get-mute)

# Others
loadavg_5min=$(cat /proc/loadavg | awk -F ' ' '{print $1}')

if [ "$audio_is_muted" = "true" ]
then
    audio_active='🔇'
else
    audio_active='🔊'
fi

echo "🏋 $loadavg_5min | $audio_active $audio_volume% | $date_and_week 🕘 $current_time"
