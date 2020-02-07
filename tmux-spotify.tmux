#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="/usr/local/bin:$PATH:/usr/sbin"

is_osx() {
    local platform=$(uname)
    [ $platform == "Darwin" ]
}

is_linux() {
    local platform=$(uname)
    [ $platform == "Linux" ]
}

main() {
    if is_osx; then
        $(tmux bind-key -T prefix S run -b "source $CURRENT_DIR/scripts/spotify_mac.sh && show_menu")
    elif is_linux; then
        $(tmux bind-key -T prefix S run -b "source $CURRENT_DIR/scripts/spotify_ux.sh && show_menu")
    fi
}

main
