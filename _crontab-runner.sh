# #!/bin/bash
#
# export PATH=<ENSURE APPROPRIATE PATH>
# source $HOME/.bashrc
# 
# case "$1" in
# request) cd FULL_PATH_TO_CI_DIR; nohup ./run.sh ./test_by_request.sh &>> crontab.log"; ;;
# commit) cd FULL_PATH_TO_CI_DIR; nohup ./run.sh ./test_on_new_commits.sh &>> crontab.log"; ;;
# *) ;;
# esac


#
# The typical crontab entry:
#
#---------
# 9,19,29,39,49,59 * * * *    FULL_PATH_TO_CI_DIR/crontab-runner.sh commit
# 0,5,10,15,20,25,30,35,40,45,50,55 * * * *    FULL_PATH_TO_CI_DIR/crontab-runner.sh request
#---------
#

