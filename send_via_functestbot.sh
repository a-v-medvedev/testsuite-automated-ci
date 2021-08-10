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
            curl -F "chat_id=${CHATID}" -F "document=@$PWD/$f" "https://api.telegram.org/bot${BOTID}/sendDocument" >& /dev/null
        done
    fi
}

function send_msg_via_functestbot() {
    local oldIFS="$IFS"
    local msg="$1"
    if [ "$2" == "markdown" ]; then
        markdown="-F parse_mode=Markdown"
        local oldIFS="$IFS"
        IFS=
        msg="$(echo $1 | sed 's/_/\\_/g')"
        IFS="$oldIFS"
    fi
    curl $markdown -F "chat_id=${CHATID}" -F "text=$msg" "https://api.telegram.org/bot${BOTID}/sendMessage" >& /dev/null
}
