#!/bin/bash

#source send_via_functestbot.sh
#source credentials.sh
#source dotests.sh
#source application.sh

[ -z "$BOTNAME" ] && echo "BOTNAME variable is not defined in credentials.sh" && exit 1
[ -z "$BOTID" ] && echo "BOTID variable is not defined in credentials.sh" && exit 1
[ -z "$CHATID" ] && echo "CHATID variable is not defined in credentials.sh" && exit 1

function filter() {
    ./JSON.sh | egrep "\[$1\]" | awk -v FS="\t" '{print $2}'
}

lastid=0
[ -f lasthandledid ] && lastid=$(cat lasthandledid)

updates=$(curl -s https://api.telegram.org/bot${BOTID}/getUpdates)
echo "$updates" | filter '"result",[0-9]*,"message"' | while read m; do
    chat_id=$(echo "$m" | filter '"chat"' | filter '"id"')
    [ "$chat_id" == "$CHATID" ] || continue
    echo "$m" | filter '"message_id"' > .id
	echo "$m" > .lastm
    [ "$lastid" != 0 -a "$(cat .id)" -gt "$lastid" ] && break
done

id=0
[ -f .id ] && id=$(cat .id)
lastm=""
[ -f .lastm ] && lastm=$(cat .lastm)

[ "$id" -gt "$lastid" -a "$id" != "0" ] || exit 0

echo $id > lasthandledid
fn=$(echo "$lastm" | filter '"from","first_name"' | tr -d \")
ln=$(echo "$lastm" | filter '"from","last_name"' | tr -d \")
text=$(echo "$lastm" | filter '"text"' | tr -d \")
date=$(echo "$lastm" | filter '"date"')
echo "REQUEST: $(date "+%F %R" --date=@$date), $fn $ln, \"$text\""
BOOT=$(echo "$text" | awk '{ if ($1 == "/boot") print $2; }')
if [ ! -z "$BOOT" ]; then
    echo "$PWD" > "$HOME/bootstrap_required"
    exit 0
fi
BRANCH=$(echo "$text" | awk '{ if ($1 == "/test") print $2; }')
[ -z "$BRANCH" ] && exit 0
[ "$BRANCH" == "$BOTNAME" ] && BRANCH=$TESTSUITE_DEFAULT_BRANCH

suites=$(echo "$text" | awk -v BOTNAME=$BOTNAME '{ if ($1 == "/test" && $NF == BOTNAME) { suites=""; for (i=3; i<NF; i++) suites=suites " " $i; } } END {print suites}')
[ -z "$suites" ] || TESTSUITE_SUITES="$suites" && true

revision=$(git ls-remote --heads "$PROJECT_URL" | grep "$BRANCH" | awk '{print $1}')
[ -z "$revision" ] && exit 0
revision=$(echo $revision | awk '{ printf "%.7s\n", $1 }')

export TESTSUITE_BRANCH=${BRANCH}
build_test_and_report "requested by $fn $ln at $(date "+%F %R" --date=@$date)"
