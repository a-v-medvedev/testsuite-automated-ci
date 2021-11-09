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

npaths=$(ls -1d *-automated-ci 2>/dev/null | wc -l)
path="$PWD"
scriptwd="$PWD"
if [ "$npaths" == "1" ]; then
    if [ -d *-automated-ci ]; then
        path=${path}/*-automated-ci
        cd $path
    fi
fi

source send_via_functestbot.sh

echo $$ > "$LOCK"
BOOTSTRAP_REQUIRED="$HOME/bootstrap_required"
if [ -f "$BOOTSTRAP_REQUIRED" ]; then
    if [ "$PWD" == $(cat "$BOOTSTRAP_REQUIRED") ]; then
        set -x
        cd $scriptwd
        [ -x ./bootstrap.sh ] && ./bootstrap.sh
        cfg_git=$(git remote -v | awk '{print $2}' | awk -F/ '{ print $(NF) }')
        cfg_hash=$(git rev-parse --short HEAD)
        rm -f "$BOOTSTRAP_REQUIRED"
        cd $path
        ci_git=$(git remote -v | awk '{print $2}' | awk -F/ '{ print $(NF) }')
        ci_hash=$(git rev-parse --short HEAD)
        msg="Test system bootstrapped, ${cfg_git}: _${cfg_hash}; ${ci_git}: _${ci_hash}_"
        send_msg_via_functestbot "$msg" "markdown"
        set +x
    fi
fi

# Args is: test_by_request.sh or test_on_new_commits.sh -- set one of them in crontab
./$1
rm -f "$LOCK"
