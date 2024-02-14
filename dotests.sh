#!/bin/bash

function build_test_and_report() {
    reason="$1"

    [ -e testsuite ] && rm -rf testsuite
    git clone --recursive "$TESTSUITE_URL" >& /dev/null || { echo "FATAL: error cloning testsuite repository"; exit 1; }

    cd testsuite || { echo "FATAL: not testsuite directory"; exit 1 }
    [ -f $HOME/.thread ] && rm -f $HOME/.thread
    ./bootstrap.sh "$TESTSUITE_CONF_URL" "$TESTSUITE_PROJECT" "$TESTSUITE_MODULE" >& fulllog.log

    cd thirdparty
    ./dnb.sh :d &>> fulllog.log || { echo "FATAL: downloading stage failed (./dnb.sh :d)"; exit 1 }
    cd ..

    ./get_timestamp.sh &>> fulllog.log 
    timestamp=$(grep 'TIMESTAMP: ' fulllog.log | awk '{ print $2 }' | head -n1)
    [ -z "$timestamp" ] || export TESTSUITE_TIMESTAMP="$timestamp"
    local machine=""
    [ -z "$TESTSUITE_HWCONF" ] || machine="\n- Machine: $TESTSUITE_HWCONF"
    local msg=\
"Functest started with timestamp *$timestamp* for application: *$TESTSUITE_PROJECT*.\n\
- Branch: *$BRANCH*\n\
- Changeset: *$revision*\n\
- Reason is: $reason$machine"
    send_msg_via_functestbot "$msg"

    ./testall.sh "$TESTSUITE_SUITES" &>> fulllog.log
    timestamp=$(grep 'TIMESTAMP: ' fulllog.log | awk '{ print $2 }' | head -n1)
    tst_revision=$(grep 'REVISION: ' fulllog.log | awk '{ printf "%.7s\n", $2 }' | head -n1)
    [ -z "$tst_revision" ] || revision=$tst_revision
    [ -z "$timestamp" ] || mv fulllog.log summary_$timestamp.log
    cd ..

    [ -z "$timestamp" ] && return 1


    for suite in $TESTSUITE_SUITES; do
        local msg=$(grep "^--- $suite: " testsuite/summary_$timestamp.log | sed 's/^--- /- /g' | grep -v 'recorded 0 failure references')
        if ! echo "$msg" | grep -q 'F=0 N=0 TACE=0'; then
            msg=$(echo "$msg" | sed 's/ F=/ *F=/;s/TACE=[0-9]*/&*/')
        fi
        send_msg_via_functestbot "$msg" "markdown"
    done

    send_files_via_functestbot "$timestamp"
    send_final_msg_via_functestbot "$timestamp"
    return 0
}


