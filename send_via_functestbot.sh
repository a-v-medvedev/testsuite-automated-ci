#!/bin/bash

function beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

function is_textfile() { grep -Iq . "$1" 2>/dev/null && true || false; }

function send_files_via_functestbot() {
    local timestamp="$1"
    nf=$(ls -1 testsuite/*$timestamp* 2>/dev/null | wc -l)
    if [ "$nf" != "0" ]; then
        for f in testsuite/*$timestamp*; do
            if is_textfile "$f"; then
                if beginswith  "text/plain" "$(file -i -b $f)"; then
                    sed -i "s/$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN/***:***/g" "$f"
                    sed -i "s/$DNB_GITLAB_ACCESS_TOKEN/***/g" "$f"
                fi
            fi
            api_send_file "$PWD/$f"
        done
    fi
}

function send_msg_via_functestbot() {
    local oldIFS="$IFS"
    local msg="$1"
    api_send_message "$msg" "$2"
}
