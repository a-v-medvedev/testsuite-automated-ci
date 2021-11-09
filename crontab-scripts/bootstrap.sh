#!/bin/bash

[ ! -f credentials.sh ] && echo "credentials.sh file required" && exit 1
[ ! -f application.sh ] && echo "application.sh file required" && exit 1

[ -d .git ] && git pull

source ./credentials.sh

[ -f testsuite-automated-ci/lasthandledid ] && cp testsuite-automated-ci/lasthandledid .
[ -f testsuite-automated-ci/lasttestedrev ] && cp testsuite-automated-ci/lasttestedrev .

rm -rf testsuite-automated-ci
git clone https://github.com/a-v-medvedev/testsuite-automated-ci.git || exit 1

cp credentials.sh testsuite-automated-ci
cp application.sh testsuite-automated-ci

[ -f lasthandledid ] && cp lasthandledid testsuite-automated-ci
[ -f lasttestedrev ] && cp lasttestedrev testsuite-automated-ci

cp testsuite-automated-ci/crontab-scripts/run.sh .
rm -f /tmp/_xxx_bootstrap_sh
mv $0 /tmp/_xxx_bootstrap_sh
cp testsuite-automated-ci/crontab-scripts/bootstrap.sh .

rm -f ~/lock


