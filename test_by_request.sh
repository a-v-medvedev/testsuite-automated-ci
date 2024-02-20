#!/bin/bash

source credentials.sh

if [ "$API" == "SLACK" ]; then
    source slack.sh
elif [ "$API" == "TELEGRAM" ]; then
    source telegram.sh
else
    echo "FATAL: API is not selected in credentials.sh"
    exit 1
fi

source send_via_functestbot.sh
source dotests.sh
source application.sh
source parse_test_cmdline.sh

MSG_COMMAND=""
MSG_NAME=""
MSG_TEXT=""
MSG_DATE=""

api_get_message

echo "REQUEST: $MSG_DATE, $MSG_NAME, \"$MSG_COMMAND $MSG_TEXT\""

case $MSG_COMMAND in
update)
    echo "$PWD" > "$HOME/update_required"
    exit 0
    ;;
test)
    parse_test_cmdline
    build_test_and_report "requested by $MSG_NAME at $MSG_DATE"
    ;;
esac


