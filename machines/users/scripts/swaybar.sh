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
media_artist=$(playerctl metadata artist)
media_song=$(playerctl metadata title)
player_status=$(playerctl status)

# Network
network=$(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ')

# Others
loadavg_5min=$(cat /proc/loadavg | awk -F ' ' '{print $2}')

if ! [ "$network" ]
then
   network_active="⛔"
else
   network_active="⇆"
fi

if [ "$player_status" = "Playing" ]
then
    song_status='▶'
elif [ "$player_status" = "Paused" ]
then
    song_status='⏸'
else
    song_status='⏹'
fi

if [ "$audio_is_muted" = "true" ]
then
    audio_active='🔇'
else
    audio_active='🔊'
fi

echo "🎧 $song_status $media_artist - $media_song  | $network_active | 🏋 $loadavg_5min | $audio_active $audio_volume% | $date_and_week 🕘 $current_time"