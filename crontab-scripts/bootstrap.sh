#!/bin/bash

#
# NOTE: this script is probably of no use anymore
#

[ ! -e credentials.sh ] && { echo "credentials.sh file required"; exit 1; }
[ ! -e application.sh ] && { echo "application.sh file required"; exit 1; }

touch ~/lock

[ -d .git ] && git pull --rebase

source ./credentials.sh

if [ -d testsuite-automated-ci ]; then
    [ -f testsuite-automated-ci/lasthandledid ] && cp testsuite-automated-ci/lasthandledid .
    [ -f testsuite-automated-ci/lasttestedrev ] && cp testsuite-automated-ci/lasttestedrev .
fi

rm -rf testsuite-automated-ci
git clone https://github.com/a-v-medvedev/testsuite-automated-ci.git || exit 1

# we already have symlinks in testsuite-automated-ci/
# cp credentials.sh testsuite-automated-ci
# cp application.sh testsuite-automated-ci

[ -f lasthandledid ] && cp lasthandledid testsuite-automated-ci
[ -f lasttestedrev ] && cp lasttestedrev testsuite-automated-ci

[ -e run.sh ] && rm run.sh
ln -s testsuite-automated-ci/crontab-scripts/run.sh .
[ -e update.sh ] && rm update.sh
ln -s testsuite-automated-ci/crontab-scripts/update.sh .

rm -f /tmp/_xxx_bootstrap_sh
mv $0 /tmp/_xxx_bootstrap_sh

cp testsuite-automated-ci/crontab-scripts/bootstrap.sh .

rm -f ~/lock
rm -f /tmp/_xxx_bootstrap_sh


