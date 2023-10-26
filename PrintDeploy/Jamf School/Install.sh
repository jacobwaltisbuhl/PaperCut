#!/bin/bash

function installdmg {
    set -e  # Exit on error
    set -o pipefail  # Exit on error in pipeline

    if [ $# -ne 1 ]; then
        echo "Usage: $0 <DMG_URL>"
        exit 1
    fi

    DMG_URL=$1
    while true; do ping -c1 print.papercutserver.local > /dev/null && break; done
    echo "Host Resolved: print.papercutserver.local"

    tempd=$(mktemp -d)
    trap "rm -rf $tempd" EXIT

    if curl -L "$DMG_URL" -o "$tempd/pkg.dmg"; then
        listing=$(sudo hdiutil attach "$tempd/pkg.dmg" | grep -m 1 Volumes)
        volume=$(echo "$listing" | cut -f 3)
        if [ -n "$volume" ]; then
            pkg_files=("$volume"/*.pkg)
            if [ -n "$pkg_files" ]; then
                package=$(ls -1 "$volume" | grep .pkg | head -1)
                sudo installer -pkg "$volume/$package" -target /
            fi 
        else
            echo "No Volumes found in DMG image."
        fi
        sudo hdiutil detach "$(echo "$listing" | cut -f 1)"
    else
        echo "Failed to download DMG from $DMG_URL."
        exit 1
    fi
}

installdmg "http://print.papercutserver.local:9191/print-deploy/client/macos"
