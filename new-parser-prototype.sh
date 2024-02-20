#!/bin/bash

function fatal() {
    local msg="$1"
    msg="Testsuite received command: $MSG_COMMAND; with args: $MSG_TEST; $msg"
}

TESTSUITE_REQUIRED_SUITES="build_variations"
TESTSUITE_AVAILABLE_HWCONFS="lumi-c lumi-g"
TESTSUITE_HWCONF="lumi-g"

MSG_COMMAND=test
MSG_TEXT="branch:main suite:xxx suite:yyy machine:lumi-g revision:0978734"

REVISION="HEAD"

for i in $MSG_TEXT; do
    value=$(echo $i | cut -d: -f2)
    case $i in
        branch:*) BRANCH=$value; ;;
        suite:*) SUITES="$SUITES $value"; ;;
        machine:*) MACHINE=$value; ;;
        revision:*) REVISION=$value; ;;
        *) fatal "*SYNTAX ERROR* in arg: $i";;
    esac
done

if [ ! -z "$TESTITEM_REQUIRED_SUITES" ]; then
    for i in $TESTITEM_REQUIRED_SUITES; do
        echo "$SUITES" | grep -q "$i" || SUITES="$i $SUITES"
    done
fi
SUITES=$(echo $SUITES | sed 's/^ *//;s/ *$//')

if [ ! -z "$BRANCH" -a "$REVISION" != "HEAD" ]; 
    fatal "*SYNTAX ERROR:* branch and revision options can't be used together"
fi

[ -z "$TESTSUITE_HWCONF" -a -z "$MACHINE" ] && exit 0

if [ ! -z "$TESTITEM_AVAILABLE_HWCONFS" ]; then
    for i in $TESTITEM_AVAILABLE_HWCONFS; do
        if [ "$MACHINE" == "$i" ]; then
            requested_hwconf="$TESTSUITE_HWCONF"
        fi
    done
fi

[ -z "$requested_hwconf" ] && TESTSUITE_HWCONF="$requested_hwconf"

[ -z "$TESTSUITE_HWCONF" ] && exit 0

if [ "$REVISION" != "HEAD" ]; then
	revision=$(echo $REVISION | awk '{ printf "%.7s\n", $1 }')
	export TESTSUITE_BRANCH="$revision"
else
	[ -z "$BRANCH" ] && BRANCH=$TESTSUITE_DEFAULT_BRANCH
	revision=$(git ls-remote --heads "$PROJECT_URL" | grep "$BRANCH" | awk '{print $1}')
	[ -z "$revision" ] && exit 0
	revision=$(echo $revision | awk '{ printf "%.7s\n", $1 }')
	export TESTSUITE_BRANCH=${BRANCH}
fi




