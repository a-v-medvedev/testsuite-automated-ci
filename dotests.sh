#!/bin/bash

function fatal_error() {
    local msg="$1"
    local file="$2"
    echo "FATAL: $1"
    send_msg_via_functestbot "Functest bootstrap phase failed: $1" "$file"
    exit 1
}

function build_test_and_report() {
    reason="$1"

    # Clone the testsuite project
    [ -e testsuite ] && rm -rf testsuite
    local branch=${TESTSUITE_TESTSUITE_BRANCH:=master}
    git clone --recursive "$TESTSUITE_TESTSUITE_URL" --depth 1 --single-branch --branch "$branch" >& /dev/null || fatal_error "error cloning testsuite repository" $PWD/fulllog.txt

    #-------------------------------------------------------------------
    #--- ENTER the testsuite directory
    cd testsuite || fatal_error "no testsuite directory for some reason" $PWD/fulllog.txt

    # Bootstraping the testsuite
    local conf_branch=${TESTSUITE_CONF_BRANCH:=HEAD}
    ./bootstrap.sh "$TESTSUITE_CONF_URL" "$TESTSUITE_PROJECT" "$TESTSUITE_MODULE" "$conf_branch" &>> ../fulllog.log || fatal_error "./bootstrap.sh execution failed" $PWD/../fulllog.log

    # Making all downloads beforehand
    ./download.sh &>> ../fulllog.log || fatal_error "downloading stage failed (./download.sh)" $PWD/../fulllog.log

    # Assign an unique timestamp to this testing session
    echo "TIMESTAMP: $(./get_timestamp.sh)" &>> ../fulllog.log 
    timestamp=$(grep 'TIMESTAMP: ' ../fulllog.log | awk '{ print $2 }' | head -n1)
    [ -z "$timestamp" ] || export TESTSUITE_TIMESTAMP="$timestamp"
    [ -z "$timestamp" ] && fatal_error "error getting the unique timestamp" $PWD/../fulllog.log

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
    ./testall.sh "$TESTSUITE_SUITES" &>> ../fulllog.log

    #--- LEAVE the testsuite directory
    cd ..
    #-------------------------------------------------------------------

    tst_revision=$(grep 'REVISION: ' fulllog.log | awk '{ printf "%.7s\n", $2 }' | head -n1)
    [ -z "$tst_revision" ] || revision=$tst_revision

    mv fulllog.log summary_$timestamp.log

    # Send final stats message
    for suite in $TESTSUITE_SUITES; do
        local msg=$(grep "^--- $suite: " summary_$timestamp.log | sed 's/^--- /- /g')
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


