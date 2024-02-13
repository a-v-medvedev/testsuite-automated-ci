#!/bin/bash

[ -z "$DNB_GITLAB_USERNAME" ] && echo "DNB_GITLAB_USERNAME variable is not defined in credentials.sh" && exit 1
[ -z "$DNB_GITLAB_ACCESS_TOKEN" ] && echo "DNB_GITLAB_ACCESS_TOKEN variable is not defined in credentials.sh" && exit 1

PROJECT_URL="https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@earth.bsc.es/gitlab/amedvede/nemogcm_v40.git"
CONF_URL="https://$DNB_GITLAB_USERNAME:$DNB_GITLAB_ACCESS_TOKEN@earth.bsc.es/gitlab/ces/hpc-for-es-team/nemo-testsuite-conf.git"
TESTSUITE_URL="https://github.com/a-v-medvedev/testsuite.git"

export TESTSUITE_PROJECT="nemo"
export TESTSUITE_DEFAULT_BRANCH="autotest"
export TESTSUITE_BUILD_CONF="generic"
export TESTSUITE_MODULE="functest"
export TESTSUITE_SCRIPT="functional"
export TESTSUITE_CONF_URL=${CONF_URL}
export TESTSUITE_SUITES="build_variations basic"

