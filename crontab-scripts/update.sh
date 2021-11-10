#!/bin/bash

[ ! -f credentials.sh ] && echo "credentials.sh file required" && exit 1
[ ! -f application.sh ] && echo "application.sh file required" && exit 1

[ -d .git ] && git pull
[ -d .git ] && git checkout master

cd testsuite-automated-ci
[ -d .git ] && git pull
[ -d .git ] && git checkout master

rm -f $HOME/lock
