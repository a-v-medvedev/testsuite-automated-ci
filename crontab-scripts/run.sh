#!/bin/bash

# This script can be run from cron. Single argument is required, see below.

# NOTE: since we are running from cron, ensure in the crontab script that
# we tuned the paths and environment correctly:
#  . ~/.bashrc
#  export PATH=$PATH:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
#
# A typical crontab job script may llok like:
#
#---------
# #!/bin/bash
#
# export PATH=<ENSURE APPROPRIATE PATH>
# source $HOME/.bashrc
# 
# case "$1" in
# request) cd FULL_PATH_TO_CI_DIR; nohup ./run.sh ./test_by_request.sh &>> crontab.log"; ;;
# commit) cd FULL_PATH_TO_CI_DIR; nohup ./run.sh ./test_on_new_commits.sh &>> crontab.log"; ;;
# *) ;;
# esac
#---------
#
# The typical crontab entry:
#
#---------
# 9,19,29,39,49,59 * * * *    FULL_PATH_TO_CI_DIR/crontab-runner.sh commit
# 0,5,10,15,20,25,30,35,40,45,50,55 * * * *    FULL_PATH_TO_CI_DIR/crontab-runner.sh request
#---------
#


scriptwd="$PWD"
LOCK="$HOME/lock"
UPDATE_REQUIRED="$HOME/update_required"
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
if [ "$npaths" == "1" ]; then
    if [ -d *-automated-ci ]; then
        path=${path}/*-automated-ci
        cd $path
    fi
fi

source credentials.sh
if [ "$API" == "SLACK" ]; then
    source slack.sh
elif [ "$API" == "TELEGRAM" ]; then
    source telegram.sh
else
    echo "FATAL: API is not selected in credentials.sh"
    exit 1
fi
source application.sh
source send_via_functestbot.sh
source dotests.sh

echo $$ > "$LOCK"
if [ -f "$UPDATE_REQUIRED" ]; then
    if [ "$PWD" == $(cat "$UPDATE_REQUIRED") ]; then
        cd $scriptwd
        [ -x ./update.sh ] && ./update.sh
        if [ -d .git ]; then
            cfg_git=$(git remote -v | awk '{print $2}' | head -n1 | awk -F/ '{ print $(NF) }')
            cfg_hash=$(git rev-parse --short HEAD)
        fi
        rm -f "$UPDATE_REQUIRED"
        cd $path
        ci_git=$(git remote -v | awk '{print $2}' | head -n1 | awk -F/ '{ print $(NF) }')
        ci_hash=$(git rev-parse --short HEAD)
        [ -z "$cfg_git" ] && msg="Test system scripts updated, ${ci_git}: *${ci_hash}*"
        [ ! -z "$cfg_git" ] && msg="Test system scripts updated, ${cfg_git}: *${cfg_hash}*; ${ci_git}: *${ci_hash}*"
        send_msg_via_functestbot "$msg" "markdown"
        echo "UPDATE FINISHED cfg=${cfg_hash}; ci=${ci_hash}"
    fi
fi

# The argument is: ./test_by_request.sh or ./test_on_new_commits.sh,  
# set one of them in your crontab caller script
$1
rm -f "$LOCK"
