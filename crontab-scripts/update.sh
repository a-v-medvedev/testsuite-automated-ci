#!/bin/bash

[ ! -f credentials.sh ] && echo "credentials.sh file required" && exit 1
[ ! -f application.sh ] && echo "application.sh file required" && exit 1

[ -d .git ] && git pull

cd testsuite-automated-ci
[ -d .git ] && git pull

rm -f $HOME/lock
