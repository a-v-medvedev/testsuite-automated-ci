#!/bin/bash

[ ! -f credentials.sh ] && echo "credentials.sh file required" && exit 1
[ ! -f application.sh ] && echo "application.sh file required" && exit 1

source ./credentials.sh

[ -f testsuite-automated-ci/lasthandledid ] && cp testsuite-automated-ci/lasthandledid .
[ -f testsuite-automated-ci/lasttestedrev ] && cp testsuite-automated-ci/lasttestedrev .

rm -rf testsuite-automated-ci
git clone https://github.com/a-v-medvedev/testsuite-automated-ci.git || exit 1

cp credentials.sh testsuite-automated-ci
cp application.sh testsuite-automated-ci

[ -f lasthandledid ] && cp lasthandledid testsuite-automated-ci
[ -f lasttestedrev ] && cp lasttestedrev testsuite-automated-ci

rm -f ~/lock


