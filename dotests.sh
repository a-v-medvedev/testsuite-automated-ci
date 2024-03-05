#!/bin/bash

function build_test_and_report() {
    reason="$1"

    # Clone the testsuite project
    [ -e testsuite ] && rm -rf testsuite
    git clone --recursive "$TESTSUITE_URL" >& /dev/null || { echo "FATAL: error cloning testsuite repository"; exit 1; }

    #-------------------------------------------------------------------
    #--- ENTER the testsuite directory
    cd testsuite || { echo "FATAL: no testsuite directory"; exit 1; }

    # FIXME .thread is a technical file for Slack interaction. Think about getting rid of it
    [ -f $HOME/.thread ] && rm -f $HOME/.thread

    # Bootstraping the testsuite
    ./bootstrap.sh "$TESTSUITE_CONF_URL" "$TESTSUITE_PROJECT" "$TESTSUITE_MODULE" >& fulllog.log

    # Making all downloads beforehand
    ./download.sh &>> ../fulllog.log  || { echo "FATAL: downloading stage failed (./download.sh)"; exit 1; }

    # Assign an unique timestamp to this testing session
    echo "TIMESTAMP: $(./get_timestamp.sh)" &>> fulllog.log 
    timestamp=$(grep 'TIMESTAMP: ' fulllog.log | awk '{ print $2 }' | head -n1)
    [ -z "$timestamp" ] || export TESTSUITE_TIMESTAMP="$timestamp"

    # Make a first message denoting the actual start of building and testing process
    local machine=""
    [ -z "$TESTSUITE_HWCONF" ] || machine="\n- Machine: *$TESTSUITE_HWCONF*"
    local msg=\
"Functest started with timestamp *$timestamp* for application: *$TESTSUITE_PROJECT*.\n\
- Branch: *$BRANCH*\n\
- Changeset: *$revision*\n\
- Reason is: $reason$machine"
    send_msg_via_functestbot "$msg"


    # Do all build and test actions
    ./testall.sh "$TESTSUITE_SUITES" &>> fulllog.log
    timestamp=$(grep 'TIMESTAMP: ' fulllog.log | awk '{ print $2 }' | head -n1)
    [ -z "$timestamp" ] && return 1
    tst_revision=$(grep 'REVISION: ' fulllog.log | awk '{ printf "%.7s\n", $2 }' | head -n1)
    [ -z "$tst_revision" ] || revision=$tst_revision
    [ -z "$timestamp" ] || mv fulllog.log summary_$timestamp.log

    #--- LEAVE the testsuite directory
    cd ..
    #-------------------------------------------------------------------

    # Send final stats message
    for suite in $TESTSUITE_SUITES; do
        local msg=$(grep "^--- $suite: " testsuite/summary_$timestamp.log | sed 's/^--- /- /g')
        if ! echo "$msg" | grep -q 'F=0 N=0 TACE=0'; then
            msg=$(echo "$msg" | sed 's/ F=/ *F=/;s/TACE=[0-9]*/&*/')
        fi
        send_msg_via_functestbot "$msg" "markdown"
    done

    # Send all the files with logs that we have so far
    send_files_via_functestbot "$timestamp"

    # Send final message
    send_final_msg_via_functestbot "$timestamp"

    # "Archive" this testsuite and all its test contents
    mv testsuite testsuite."$timestamp"

    return 0
}


