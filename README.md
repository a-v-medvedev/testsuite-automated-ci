# testsuite-automated-ci

## About
This projects includes a number of CI automation scripts for `testsuite` project (https://github.com/a-v-medvedev/testsuite).

It incorporates some scripts for crontab and some scripts that take commands from Telegram Instant Messaging chats.

## Setting up

To make it all work, do the actions as listed below.

1. Create a new git project which includes:
- `application.sh` file. Use a provided here `_application.sh` file as a template.
- `credentials.sh` file. Use a provided here `_credentials.sh` file as a template. See Credetial section below for reference.
- Add this git project as a submodule to yur project:
```
git submodule add https://github.com/a-v-medvedev/testsuite-automated-ci.git testsuite-automated-ci
git commit -am "Submodule added for testsuite-automated-ci."
```
- Add symlinks and commit them:
```
ln -s testsuite-automated-ci/crontab-scripts/run.sh run.sh
ln -s testsuite-automated-ci/crontab-scripts/update.sh update.sh
git commit -am "Symlinks for main scripts added."
```

2. Clone this project on a target machine:
Push all changes and go to target machine and a selected directory. Don't forget to be logged in with an account which is going to be used for cron-based automated work in production.
```
git clone --recursive <URL-TO-GIT-PORJECT>
```

3. Check that it basically works:
```
bash# cd <DIRECTORY-OF-CLONED-PROJECT>
bash# ./update.sh
Already up-to-date.
Already up-to-date.
bash# ./run.sh test_by_request.sh
bash#
```

4. Add `crontab` records for periodical check of events:
```
SHELL=/bin/bash
MAILTO=<username>
* * * * *    $WORKING_DIR/run.sh test_on_new_commits.sh
* * * * *    $WORKING_DIR/run.sh test_by_request.sh
```

5. Check if `testsuite` starts on new commits to the target project branch (which is set up in `application.sh`).

6. Check if `testsuite` starts by request from testbot chat.



## Credentials

You have to get Telegram chat id and save it in `credentials.sh` file. You basically create a telegram chat (you need at least two people to create a chat in Telegram, but this is required only on a chat creation stage, then only one person may stay in a chat.

When the chat is created, it is time to create a new Telegram bot using standard procedure og `@botfather` interaction (don't forget to add permissions to the bot so that it could read and write to a chat). You can also re-use the same bot many times for different chats.

When the bot is added to the chat, you can find out the your char-id by writing messages to the bot and reading them then by a script like:
```
curl -s https://api.telegram.org/bot${BOTID}/getUpdates
```

The output of the script will contain `chat_id` field which yoyu need to save.

So, from Telegram side, you need three values:
- `BOTNAME="@XXXXXXX:`
- `BOTID="NNNNNNNN:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"`
- `CHATID="-NNNNNNNNNNNNNNNN"`

The `DNB_GITLAB_ACCESS_TOKEN` and `DNB_GITLAB_USERNAME` may be useful ones to set if your target project is one residing on the password-protected part of `gitlab.com` hub. If you have some other password-protected facilities in your target project download-and-build routines, it is good idea to put codes in environment values just in this file. 

You don't have to put the `credentials.sh` file in the repository. You also can hold it by direct hand-copying it to the target machine for security reasons.


## Bot commands

Currenty Telegram bot interaction script is able to handle two commands:

### `/update`

Used to automatically start the `update.sh` script in the working directory to download the latest version of all scripts without a necessety to log in the the target machine.

### `/test`

Used to manually initiate test procedure for a selected branch.

`/test` with no args just starts a test procedure for a HEAD of default branch.

`/test BRANCH` starts the procedure for HEAD of a specific branch.

`/test BRANCH SUITE1 SUITE2 SUITE3` starts only selected suites for a specific branch.




