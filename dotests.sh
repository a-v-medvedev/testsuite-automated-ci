#!/bin/bash

function build_test_and_report() {
    reason="$1"

    [ -e testsuite ] && rm -rf testsuite
    git clone --recursive "$TESTSUITE_URL" >& /dev/null || exit 1

    cd testsuite || exit 1
    ./testall.sh "$TESTSUITE_SUITES" >& fulllog.log
    timestamp=$(grep 'TIMESTAMP: ' fulllog.log | awk '{ print $2 }')
    tst_revision=$(grep 'REVISION: ' fulllog.log | awk '{ printf "%.7s\n", $2 }')
    [ -z "$tst_revision" ] || revision=$tst_revision
    [ -z "$timestamp" ] || mv fulllog.log summary_$timestamp.log
    cd ..

    [ -z "$timestamp" ] && return 1

    send_msg_via_functestbot "Functest report for timestamp *$timestamp*. Made for application: *$TESTSUITE_PROJECT*, branch: *$BRANCH*, changeset: *$revision*, reason is: $reason." "markdown"

    for suite in $TESTSUITE_SUITES; do
        local msg=$(grep "^--- $suite: " testsuite/summary_$timestamp.log | sed 's/^--- /- /g' | grep -v 'recorded 0 failure references')
        if ! echo "$msg" | grep -q 'F=0 N=0 TACE=0'; then
            msg=$(echo "$msg" | sed 's/ F=/ *F=/;s/TACE=[0-9]*/&*/')
        fi
        send_msg_via_functestbot "$msg" "markdown"
    done

    send_files_via_functestbot "$timestamp"
    return 0
}


