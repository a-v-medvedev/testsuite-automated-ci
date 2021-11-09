#!/bin/bash

# This script can be run from cron. Single argument is required, see below.

. ~/.bashrc
export PATH=$PATH:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

LOCK="$HOME/lock"
pid=""
N=""
cd $(dirname $0)
sleep $((1 + $RANDOM % 50))
[ -f "$LOCK" ] && pid=$(cat "$LOCK")
[ "$pid" == "lock" ] && exit 0
[ -z "$pid" ] || N=$(ps -p "$pid" --no-headers | wc -l)
[ "$N" == "1" ] && exit 0
if [ ! -z "$pid" ]; then
    for i in $(seq 1 1 10); do
	sleep 1
        [ ! -f "$LOCK" ] && pid="" && break
    done
    [ ! -z "$pid" ] && rm -f "$LOCK"
fi

BOOTSTRAP_REQUIRED="$HOME/bootstrap_required"
if [ -f "$BOOTSTRAP_REQUIRED" ]; then
    [ -x ./bootstrap.sh ] && ./bootstrap.sh
    rm -f "$BOOTSTRAP_REQUIRED"
fi


npaths=$(ls -1d *-automated-ci 2>/dev/null | wc -l)
if [ "$npaths" == "1" -a -d *-automated-ci ]; then
    path=*-automated-ci
    cd $path
fi

echo $$ > "$LOCK"
# Args is: test_by_request.sh or test_on_new_commits.sh -- set one of them in crontab
./$1
rm -f "$LOCK"
