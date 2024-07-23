#!/bin/bash

function fatal() {
    local msg="$1"
    msg="Testsuite received command: $MSG_COMMAND; with args: $MSG_TEXT; $msg"
    api_send_message "$msg" "markdown"
    exit 1
}

function parse_test_cmdline() {
    local REVISION="HEAD"
    for i in $MSG_TEXT; do
	value=$(echo $i | cut -d: -f2-)
	case $i in
            branch:*) BRANCH=$value; ;;
            suite:*) suites="$suites $value"; ;;
            machine:*) MACHINE=$value; ;;
            revision:*) REVISION=$value; ;;
            env:*) ENV="$ENV $value"
            *) fatal "*SYNTAX ERROR* in arg: $i";;
        esac
    done

    if [ ! -z "$ENV" ]; then
        for exp in $ENV; do
            eval export $exp
        done
    fi

    [ -z "$suites" ] && suites="$TESTSUITE_SUITES"
    [ -z "$suites" ] && fatal "No default set of suites is set up."
	if [ ! -z "$TESTSUITE_REQUIRED_SUITES" ]; then
		for i in $TESTSUITE_REQUIRED_SUITES; do
			echo "$suites" | grep -wq "$i" || suites="$i $suites" && true
		done
	fi
	suites=$(echo $suites | sed 's/^ *//;s/ *$//')
	[ -z "$suites" ] || TESTSUITE_SUITES="$suites" && true

	if [ ! -z "$BRANCH" -a "$REVISION" != "HEAD" ]; then
		fatal "*SYNTAX ERROR:* branch and revision options can't be used together"
	fi

	[ -z "$TESTSUITE_HWCONF" -a -z "$MACHINE" ] && exit 0

    [ -z "$TESTSUITE_HWCONF" -a -z "$TESTSUITE_AVAILABLE_HWCONFS" ] && fatal "Conf error: HWCONF is not set"

    [ -z "$TESTSUITE_AVAILABLE_HWCONFS" ] && TESTSUITE_AVAILABLE_HWCONFS="$TESTSUITE_HWCONF"

    for i in $TESTSUITE_AVAILABLE_HWCONFS; do
        if [ "$MACHINE" == "$i" ]; then
            requested_hwconf="$i"
        fi
    done

    [ -z "$requested_hwconf" -a ! -z "$MACHINE" ] && exit 0

	[ -z "$requested_hwconf" ] || TESTSUITE_HWCONF="$requested_hwconf" && true

	[ -z "$TESTSUITE_HWCONF" ] && exit 0

	if [ "$REVISION" != "HEAD" ]; then
		revision=$(echo $REVISION | awk '{ printf "%.7s\n", $1 }')
		export TESTSUITE_BRANCH="$revision"
	else
		[ -z "$BRANCH" ] && BRANCH=$TESTSUITE_DEFAULT_BRANCH
		revision=$(git ls-remote --heads "$PROJECT_URL" | grep "$BRANCH" | awk '{print $1}')
		[ -z "$revision" ] && fatal "*ERROR:* Can't find branch $BRANCH in the project."
		revision=$(echo $revision | awk '{ printf "%.7s\n", $1 }')
		export TESTSUITE_BRANCH=${BRANCH}
	fi
}


