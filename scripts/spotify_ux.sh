#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="/usr/local/bin:$PATH:/usr/sbin"

open_spotify() {
    $(spotify) 
}

toggle_play_pause() {
  a=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause)
}

previous_track() {
  a=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous)
}

next_track() {
  a=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next)
}

toggle_repeat() {
  if [ "$1" == "true" ]; then
    $(osascript -e "tell application \"Spotify\" to set repeating to false")
  else
    $(osascript -e "tell application \"Spotify\" to set repeating to true")
  fi
}

toggle_shuffle() {
  if [ "$1" == "true" ]; then
    $(osascript -e "tell application \"Spotify\" to set shuffling to false")
  else
    $(osascript -e "tell application \"Spotify\" to set shuffling to true")
  fi
}

show_menu() {
    local id=$(pidof spotify)

    if [ "$id" == "" ]; then
        $(tmux display-menu -T "#[align=centre fg=green]Spotify" -x R -y P \
            "Open Spotify"     o "run -b 'source \"$CURRENT_DIR/spotify_ux.sh\" && open_spotify'" \
            "" \
            "Close menu"       q "" \
    )
    else
        local stat=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus')
        local datas=($(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata')) 
        if $(echo $stat | grep -q "Playing"); then
            local color="green"
        else
            local color="yellow"
        fi
        ## Extract data
        declare -A META
        local meta_len=${#datas[@]}
        for (( i=0; i<${meta_len}; ))
        do
            if [[ ${datas[$i]} == *"entry("* ]];then
                i=$(expr $i + 2)
                key=${datas[$i]}
                i=$(expr $i + 2)
                tp=${datas[$i]}
                i=$(expr $i + 1)
                if [[ $tp == *"array"* ]]; then
                    i=$(expr $i + 2)
                    value=${datas[$i]}
                    while true
                    do
                        if [[ $value == '"'*'"' ]];then
                            break
                        else
                            i=$(expr $i + 1)
                            value="${value} ${datas[$i]}"
                        fi
                    done
                fi
                if [[ $tp == *"string"* ]];then
                    value=${datas[$i]}
                    while true
                    do
                        if [[ $value == '"'*'"' ]];then
                            break
                        else
                            i=$(expr $i + 1)
                            value="${value} ${datas[$i]}"
                        fi
                    done
                fi
                if [[ $tp == *"int"* ]];then
                    value=${datas[$i]}
                fi
                if [[ $tp == *"double"* ]];then
                    value=${datas[$i]}
                fi
                i=$(expr $i + 1)
                META["$key"]="${value}"
                #echo "$key : ${META[$key]}"
            fi
            i=$(expr $i + 1)
        done
        $(tmux display-menu -T "#[align=centre fg=$color]Spotify" -x R -y P \
            "#[align=left fg=blue]Track: #[align=right fg=$color]${META["\"xesam:title\""]}" "" "" \
            "#[align=left fg=blue]Artist: #[align=right fg=$color]${META["\"xesam:artist\""]}" "" "" \
            "#[align=left fg=blue]Album: #[align=right fg=$color]${META["\"xesam:album\""]}" "" "" \
            "#[align=left fg=blue]Track album: #[align=right fg=$color]${META["\"xesam:trackNumber\""]}" "" "" \
            "" \
            "Play/Pause" p "run -b 'source \"$CURRENT_DIR/spotify_ux.sh\" && toggle_play_pause'" \
            "Previous"   b "run -b 'source \"$CURRENT_DIR/spotify_ux.sh\" && previous_track'" \
            "Next"       n "run -b 'source \"$CURRENT_DIR/spotify_ux.sh\" && next_track'" \
            "" \
            "Close menu" q "" \
    )
  fi
}
