#!/usr/bin/env bash

INP=$(rofi -dmenu -p "Internet:" -config ~/.config/rofi/config-search.rasi)

if [ -n "$INP" ]; then
    # Split the input into the first word and the rest of the string
    read -r FIRST_WORD REST_OF_QUERY <<< "$INP"

    # Regex to detect URLs (handles http/https, www, standard domains, and localhost)
    URL_REGEX='^(https?://|www\.|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}|localhost)(:[0-9]+)?(/.*)?$'

    if [[ "$FIRST_WORD" == '\i' ]]; then
        # DuckDuckGo Image Search
        firefox "duckduckgo.com/?t=ffab&q=\!i+$REST_OF_QUERY"
        
    elif [[ "$INP" =~ ^https?:// ]] || [[ ! "$INP" =~ [[:space:]] && "$INP" =~ $URL_REGEX ]]; then
        # Auto-detect URL:
        # Matches if it strictly starts with http:// or https://
        # OR if it has NO spaces AND matches the URL_REGEX (e.g., archlinux.org)
        firefox "$INP"
        
    else
        # Default to Google Search
        firefox "www.google.com/search?q=$INP"
    fi
fi
