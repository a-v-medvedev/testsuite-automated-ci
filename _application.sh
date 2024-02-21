#!/bin/bash

echo ">> application.sh is generic! Edit it or replace with an actual one."
exit 1

#[ -z "$DNB_GITLAB_USERNAME" ] && echo "DNB_GITLAB_USERNAME variable is not defined in credentials.sh" && exit 1
#[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && echo "DNB_GITLAB_ACCESS_TOKEN variable is not defined in credentials.sh" && exit 1

#PROJECT_URL="https://...git"   # Example: "https://github.com/a-v-medvedev/teststub.git"
#CONF_URL="https://...git"      # Example: "https://github.com/a-v-medvedev/testsuite_confs.git"
#TESTSUITE_URL="https://github.com/a-v-medvedev/testsuite.git"

#export TESTSUITE_AVAILABLE_HWCONFS="machine1 machine2"
#export TESTSUITE_HWCONF="..."   # default hwconf. Empty if there is default 
                                 # value: nothing starts without explicit mentioning of a machine
#export TESTSUITE_PROJECT="..."  # Example: "teststub"
#export TESTSUITE_DEFAULT_BRANCH="master"
#export TESTSUITE_BUILD_CONF="generic"
#export TESTSUITE_MODULE="functest"     # the only meaningful value
#export TESTSUITE_SCRIPT="functional"   # the only meaningful value
#export TESTSUITE_CONF_URL=${CONF_URL}
#export TESTSUITE_SUITES="build_variations basic"
#export TESTSUITE_REQUIRED_SUITES="build_variations"  # those suites will be automatically added if not mentioned

