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
    BRANCH=$(echo "$MSG_TEXT" | awk '{ print $1; }')    
    [ -z "$BRANCH" ] && BRANCH=$TESTSUITE_DEFAULT_BRANCH
    suites=$(echo "$MSG_TEXT" | awk '{ suites=""; for (i=2; i<=NF; i++) suites=suites " " $i; } END {print suites}')
    [ -z "$suites" ] || TESTSUITE_SUITES="$suites" && true
    revision=$(git ls-remote --heads "$PROJECT_URL" | grep "$BRANCH" | awk '{print $1}')
    [ -z "$revision" ] && exit 0
    revision=$(echo $revision | awk '{ printf "%.7s\n", $1 }')

    export TESTSUITE_BRANCH=${BRANCH}
    build_test_and_report "requested by $MSG_NAME at $MSG_DATE"
    ;;
esac


