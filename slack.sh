#!/bin/bash

[ -z "$BOTID" ] && echo "BOTID variable is not defined in credentials.sh" && exit 1
[ -z "$CHATID" ] && echo "CHATID variable is not defined in credentials.sh" && exit 1
[ -z "$APITOKEN" ] && echo "APITOKEN variable is not defined in credentials.sh" && exit 1

check_error() {
    [ "$(echo $1 | jq -r .ok)" == "false" ] && { echo ">> API ERROR:" $(echo "$1" | jq -r ".error"); exit 1; }
}

warn_on_error() {
    [ "$(echo $1 | jq -r .ok)" == "false" ] && { echo "WARNING: API ERROR:" $(echo "$1" | jq -r ".error"); }
}

find_bot_name() {
    local action=auth.test
    local x=$(curl -s -X POST \
                -H "Authorization: Bearer $APITOKEN" \
                https://slack.com/api/$action)
    check_error "$x"
    echo $x
}

# Function to send a message to Slack channel
send_message() {
    local text="$1"
    local markdown="$2"
    local action="chat.postMessage"
    local thread=""
    [ -f "$HOME/.thread" ] && thread=",\"thread_ts\":\"$(cat $HOME/.thread)\""
    local x=$(curl -s -X POST \
                -H "Authorization: Bearer $APITOKEN" \
                -H "Content-Type: application/json" \
                -d "{\"channel\":\"$CHATID\",\"text\":\"$text\"$markdown$thread}" \
                "https://slack.com/api/$action")
    check_error "$x"
    [ -f "$HOME/.thread" ] || echo $x | jq -r ".ts" > $HOME/.thread
    echo $x
}

send_file() {
    local file=$1
    local filename=$(basename "$file")
    local filesize=$(stat -c%s "$file")
    local mimetype=$(file -b --mime-type "$file")
    local do_post=false

    case $mimetype in
    text/*) do_post=true;;
    esac

    local thread=""
    [ -f "$HOME/.thread" ] && thread="--form thread_ts=\"$(cat "$HOME/.thread")\""
    local saved
    if [ -e files_storage ]; then
      local sd=$(readlink files_storage)
      [ -d $sd ] && { saved=$sd/$filename; cp $file $saved; }
    fi
    if [ "$do_post" == "true" ]; then
      local contents="$(echo -ne 'text=File contents: '$filename'\001```\001')$(head -n22 $file | sed 's/`/\`/g')$(echo -ne '\001...skipped...\001')$(tail -n22 $file | sed 's/`/\`/g')$(echo -ne '\001```\001\001')"
      local contents_=$(echo "$contents" | tr '\001' '\n')
      local status=$(curl -X POST -H "Authorization: Bearer $APITOKEN" \
        --form 'channel="'$CHATID'"' \
        --form "$contents_" $thread \
        https://slack.com/api/chat.postMessage)
      check_error "$status"
      echo "$status"
    else
      local message
      if [ -z "$saved" ]; then
        message="The realted file: $file, try to locate it somewhere around $PWD"
      else
        message="The related file: $saved"
      fi
      local status=$(curl -X POST -H "Authorization: Bearer $APITOKEN" \
        --form 'channel="'$CHATID'"' \
        --form 'text='"$message" $thread \
        https://slack.com/api/chat.postMessage)
      check_error "$status"
      echo "$status"
    fi
}

# send_file() {
#     local file=$1
#     local action="files.upload"
#     local thread=""
#     [ -f "$HOME/.thread" ] && thread="{\"thread_ts\":\"$(cat $HOME/.thread)\"}"
#     local x
#     if [ -z "$thread" ]; then
#         x=$(curl -s -F file=@$file \
#                       -F channels=$CHATID \
#                       -F token=$APITOKEN \
#                       "https://slack.com/api/$action")
#     else
#         x=$(curl -s -F file=@$file \
#                       -F channels=$CHATID \
#                       -F token=$APITOKEN \
#                       -F "thread_ts=$thread" \
#                       "https://slack.com/api/$action")
#     fi
#     check_error "$x"
#     echo $x
# }

# Function to retrieve messages from Slack channel
get_messages() {
    local action="conversations.history"
    local x=$(curl -s \
                -H "Authorization: Bearer $APITOKEN" \
                "https://slack.com/api/$action?channel=$CHATID")
    check_error "$x"
    echo $x
}

get_replies() {
    local action="conversations.replies"
    local x=$(curl -s \
                -H "Authorization: Bearer $APITOKEN" \
                "https://slack.com/api/$action?channel=$CHATID&ts=$1")
    check_error "$x"
    echo $x
}

get_user_info() {
    local user_id="$1"
    local action="users.info"
    local x=$(curl -s \
                -H "Authorization: Bearer $APITOKEN" \
                "https://slack.com/api/$action?user=$user_id")
    check_error "$x"
    echo $x
}

# Function to delete a message from a Slack channel
delete_message() {
    local message_id="$1"
    local action="chat.delete"
    local x=$(curl -s -X POST \
                -H "Authorization: Bearer $APITOKEN" \
                -H "Content-type: application/json" \
                --data "{\"channel\":\"$CHATID\",\"ts\":\"$message_id\"}" \
                "https://slack.com/api/$action")
    warn_on_error "$x"
    echo $x
}


delete_all() {
    local x
    # Get messages from the channel
	response=$(get_messages)
	for message in $(echo "$response" | jq -r ".messages[] | select(.user == \"$BOTID\") | .ts"); do
        # Get replies
        replies=$(get_replies "$message")
    	for reply in $(echo "$replies" | jq -r '.messages[] | .ts'); do
			x=$(delete_message "$reply")
		done
		x=$(delete_message "$message")
	done
}


say_hello() {
    lastid=0
    idtorecord=0
    [ -f lasthandledid ] && lastid=$(cat lasthandledid)

    # Get messages from Slack channel
    response=$(get_messages)

    messages=$(echo "$response" | jq -r '.messages')
    N=$(echo "$messages" | jq -r '.[] | length' | wc -l)
    echo ">>>> $N"
    [ "$N" == 0 ] && return
   
    for i in $(seq $(expr $N - 1) -1 0); do 
        m=$(echo $messages | jq -r ".[$i]")
        tp=$(echo $m | jq -r ".type")
        st=$(echo $m | jq -r ".subtype")
        [ "$tp" == "message" -a "$st" == "null" ] || continue

        text=$(echo $m | jq -r ".text")

        # Check if message contains "hello"
        if [[ $text == *"hello"* ]]; then
            timestamp=$(echo $m | jq -r '.ts' | sed 's/\.//')
            [ "$timestamp" -le "$lastid" ] && continue

            # Get user info
            user_id=$(echo $m | jq -r '.user')
            user_info=$(get_user_info "$user_id")
            real_name=$(echo "$user_info" | jq -r '.user.real_name')
            display_name=$(echo "$user_info" | jq -r '.user.profile.display_name_normalized')

            # Use real name if available, otherwise use display name
            username="$real_name"
            [ "$username" == "null" ] && username="$display_name"
            usertag=""
            usertag="<@$user_id>"
            #[ "$display_name" == "null" ] || usertag="@$display_name"
            
            # Respond to user
            send_message "Hello, $username! $usertag"
            [ "$idtorecord" -lt "$timestamp" ] && idtorecord=$timestamp
            break
        fi
    done
    [ "$idtorecord" != "0" ] && echo "$idtorecord" > lasthandledid
}


function api_get_message() {
    local lastid=0
    local idtorecord=0
    [ -f lasthandledid ] && lastid=$(cat lasthandledid)

    # Get messages from Slack channel
    local response=$(get_messages)

    local messages=$(echo "$response" | jq -r '.messages')
    local N=$(echo "$messages" | jq -r '.[] | length' | wc -l)
    [ "$N" == 0 ] && exit 0
   
    for i in $(seq $(expr $N - 1) -1 0); do 
        local m=$(echo $messages | jq -r ".[$i]")
        local tp=$(echo $m | jq -r ".type")
        local st=$(echo $m | jq -r ".subtype")
        [ "$tp" == "message" -a "$st" == "null" ] || continue

        local text=$(echo $m | jq -r ".text")

        # Check if message starts with a plus
        if [[ $text == "!"* ]]; then
            local timestamp=$(echo $m | jq -r '.ts' | sed 's/\.//')
            [ "$timestamp" -le "$lastid" ] && continue

            # Get user info
            local user_id=$(echo $m | jq -r '.user')
            local user_info=$(get_user_info "$user_id")
            local real_name=$(echo "$user_info" | jq -r '.user.real_name')
            local display_name=$(echo "$user_info" | jq -r '.user.profile.display_name_normalized')

            # Use real name if available, otherwise use display name
            local username="$real_name"
            [ "$username" == "null" ] && username="$display_name"

            MSG_NAME="$username"
            MSG_USERID="$user_id"
            local date=$(expr $timestamp / 1000000)
            MSG_DATE="$(date "+%F %R" --date=@$date)"
            MSG_TEXT=$(echo "$text" | awk '{for (i=2;i<=NF;i++) printf $i " "; printf "\n"}')
            MSG_COMMAND=$(echo $text | awk '{print substr($1,2)}') 
            [ "$idtorecord" -lt "$timestamp" ] && idtorecord=$timestamp
            break;
        fi
    done
    [ "$idtorecord" != "0" ] && echo "$idtorecord" > lasthandledid
    [ -z "$MSG_COMMAND" ] && exit 0
    return 0
}

function api_send_file() {
    local f="$1"
    local response=$(send_file "$f")
    return 0
}

function api_send_message() {
    local usertag=""
    [ -z $MSG_USERID ] || usertag="<@$MSG_USERID>"
    [ -f "$HOME/.thread" ] && usertag=""
    local markdown=""
    [ "$2" == "markdown" ] && markdown=",\"mrkdwn\":true"
    local response=$(send_message "$1 $usertag" "$markdown")
    return 0
}

function api_send_final_message() {
    local usertag=""
    [ -z $MSG_USERID ] || usertag="<@$MSG_USERID>"
    api_send_message "$1 $usertag"
    [ -f "$HOME/.thread" ] && rm -f "$HOME/.thread"
}

#find_bot_name
#exit 0

#delete_all
#exit 0

#say_hello
#exit 0

#api_get_message && echo ">> Have: \"$MSG_TEXT\" from $MSG_NAME ($MSG_USERID) at $MSG_DATE"
#api_send_file aaa.tgz
