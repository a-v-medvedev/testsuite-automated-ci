#/bin/bash

source credentials.sh

if [ "$API" == "SLACK" ]; then
    source slack.sh
elif [ "$API" == "TELEGRAM" ]; then
    source telegram.sh
else
    echo "FATAL: API is not selected in credentials.sh"
    exit 1
fi

source send_via_functestbot.sh
source dotests.sh
source application.sh

BRANCH="$TESTSUITE_DEFAULT_BRANCH"

revision=$(git ls-remote --heads "$PROJECT_URL" 2>/dev/null | grep "refs/heads/$BRANCH$" | awk '{print $1}')
if [ -z "$revision" ]; then exit 0; fi
[ -f lasttestedrev ] && oldrevision=$(cat lasttestedrev)
if [ "$revision" == "$oldrevision" ]; then exit 0; fi
echo $revision > lasttestedrev
revision=$(echo $revision | awk '{ printf "%.7s\n", $1 }')

echo "NEW REVISION: $revision, branch: $BRANCH"

# FIXME .thread is a technical file for Slack interaction. Think about getting rid of it
[ -f $HOME/.thread ] && rm -f $HOME/.thread

export TESTSUITE_BRANCH=${BRANCH}
build_test_and_report "new commit in this branch appeared"

