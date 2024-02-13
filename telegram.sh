#!/bin/bash

[ -z "$BOTNAME" ] && echo "BOTNAME variable is not defined in credentials.sh" && exit 1
[ -z "$BOTID" ] && echo "BOTID variable is not defined in credentials.sh" && exit 1
[ -z "$CHATID" ] && echo "CHATID variable is not defined in credentials.sh" && exit 1

function filter() {
    ./JSON.sh | egrep "\[$1\]" | awk -v FS="\t" '{print $2}'
}

function api_get_message() {
    local lastid=0
    [ -f lasthandledid ] && lastid=$(cat lasthandledid)

    local updates=$(curl -s https://api.telegram.org/bot${BOTID}/getUpdates)
    echo "$updates" | filter '"result",[0-9]*,"message"' | while read m; do
        chat_id=$(echo "$m" | filter '"chat"' | filter '"id"')
        [ "$chat_id" == "$CHATID" ] || continue
        echo "$m" | filter '"message_id"' > .id
        echo "$m" > .lastm
        [ "$lastid" != 0 -a "$(cat .id)" -gt "$lastid" ] && break
    done

    local id=0
    [ -f .id ] && id=$(cat .id)
    local lastm=""
    [ -f .lastm ] && lastm=$(cat .lastm)

    [ "$id" -gt "$lastid" -a "$id" != "0" ] || exit 0

    echo $id > lasthandledid
    local fn=$(echo "$lastm" | filter '"from","first_name"' | tr -d \")
    local ln=$(echo "$lastm" | filter '"from","last_name"' | tr -d \")
    local text=$(echo "$lastm" | filter '"text"' | tr -d \")
    local date=$(echo "$lastm" | filter '"date"')
    MSG_NAME="$fn $ln"
    MSG_USERID=""
    MSG_TEXT=$(echo "$text" | awk '{for (i=2;i<NF;i++) printf $i " "; printf "\n"}')
    MSG_COMMAND=$(echo $text | awk '{print substr($1,2)}')
    MSG_DATE="$(date "+%F %R" --date=@$date)"
}

function api_send_message() {
    local msg=$1
    if [ "$2" == "markdown" ]; then
        local oldIFS="$IFS"
        IFS=
        msg="$(echo $1 | sed 's/_/\\_/g')"
        IFS="$oldIFS"
    fi
    local markdown=""
    [ "$2" == "markdown" ] && markdown="-F parse_mode=Markdown"
    curl -s $markdown -F "chat_id=${CHATID}" -F "text=$msg" "https://api.telegram.org/bot${BOTID}/sendMessage" > /dev/null 
}

function api_send_file() {
    curl -s -F "chat_id=${CHATID}" -F "document=@$1" "https://api.telegram.org/bot${BOTID}/sendDocument" > /dev/null 
}

