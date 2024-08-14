#!/bin/bash

function beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

function is_textfile() { grep -Iq . "$1" 2>/dev/null && true || false; }

function hide_secret_info() {
    local f="$1"
    if is_textfile "$f"; then
	if beginswith  "text/plain" "$(file -i -b $f)"; then
	    sed -i "s/$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN/***:***/g" "$f"
	    sed -i "s/$DNB_GITLAB_ACCESS_TOKEN/***/g" "$f"
	fi
    fi
    return 0
}

function send_files_via_functestbot() {
    local timestamp="$1"
    nf=$(ls -1 testsuite/*$timestamp* summary_$timestamp.log 2>/dev/null | wc -l)
    if [ "$nf" != "0" ]; then
        for f in testsuite/*$timestamp* summary_$timestamp.log; do
            hide_secret_info "$f"  
            api_send_file "$PWD/$f"
        done
    fi
}

function send_msg_via_functestbot() {
    local msg="$1"
    local file="$2"
    api_send_message "$msg" "$2"
    if [ ! -z "$file" -a -f "$file" ]; then
        hide_secret_info "$file"  
        api_send_file "$file"
    fi
}

function send_final_msg_via_functestbot() {
    local timestamp="$1"
    api_send_final_message "All actions for *$timestamp* are finished" "markdown"
}
