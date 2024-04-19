# testsuite-automated-ci

## About

This projects includes a number of CI automation scripts for `testsuite` project (https://github.com/a-v-medvedev/testsuite).

It incorporates some scripts for crontab and some scripts that take commands from Telegram Instant Messaging chats or Slack messaging channels.

## Setting up

To make it all work, do the actions as listed below.

1. Create a new git project which includes:

- `application.sh` file. Use a provided here `_application.sh` file as a template.
- `credentials.sh` file. Use a provided here `_credentials.sh` file as a template. See Credential section below for reference.
- Add this git project as a submodule to your project:
```
git submodule add https://github.com/a-v-medvedev/testsuite-automated-ci.git testsuite-automated-ci
git commit -am "Submodule added for testsuite-automated-ci."
```
- Add symlinks and commit them:
```
ln -s testsuite-automated-ci/crontab-scripts/*.sh .
git commit -am "Symlinks for main scripts added."
```
> NOTE: You don't have to put the `credentials.sh` file in the repository. You also can hold it by direct hand-copying it to the target machine for security reasons. Don't even try to put Slack API tokens to a public repositories: such actions are constantly tracked by Slack and result is consequences. Holding such info in closed private repository is up to you.


2. Clone this project on a target machine:

Push all changes and go to target machine into a selected directory. Don't forget to be logged in with an account which is going to be used for cron-based automated work in production.
```
git clone --recursive <URL-TO-GIT-PORJECT>
```

3. Check that it basically works:

```
bash# cd <DIRECTORY-OF-CLONED-PROJECT>
bash# ./update.sh
Already up-to-date.
Already up-to-date.
bash# ./run.sh ./test_by_request.sh
bash#
```

4. Add `crontab` records for periodical check of events:

```
SHELL=/bin/bash
MAILTO=<username>
* * * * *    $WORKING_DIR/run.sh ./test_on_new_commits.sh
* * * * *    $WORKING_DIR/run.sh ./test_by_request.sh
```

5. Check if `testsuite` starts on new commits 

Check if scripting starts after some new commits to the target project branch (which is set up in `application.sh`).

6. Check if `testsuite` starts by request 

If you explicitely request test from a Telegram or Slack chat, check that scripting really starts and reports results.



## Credentials

### Tokens for your main repositories

The `DNB_GITLAB_ACCESS_TOKEN` and `DNB_GITLAB_USERNAME` variables may appear useful ones to set if your target project is one residing on the password-protected part of `gitlab.com` hub. If you have some other password-protected facilities in your target project download-and-build routines, it is good idea to put codes in environment values just in this file. 

### Telegram integration case:

You have to get Telegram chat id and save it in `credentials.sh` file. You basically create a telegram chat (you need at least two people to create a chat in Telegram, but this is required only on a chat creation stage, then only one person may stay in a chat; the second one can leave it).

When the chat is created, it is time to create a new Telegram bot using standard procedure of `@botfather` interaction (don't forget to add permissions to the bot so that it could read and write to a chat). You can also re-use the same bot many times for different chats.

When the bot is added to the chat, you can find out the your char-id by writing messages to the bot and reading them then by a script like:
```
curl -s https://api.telegram.org/bot${BOTID}/getUpdates
```

The output of the script will contain `chat_id` field which you need to save.

So, from Telegram side, three values are required:
- `BOTNAME="@XXXXXXX`
- `BOTID="NNNNNNNN:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"`
- `CHATID="-NNNNNNNNNNNNNNNN"`

Save these values in your `credentials.sh`.

### Slack integration case:

You have to create a Slack "application", introduce a bot functionality in it,
add this application to your Slack channel. Here are some instructions:

#### Making an Application, a Chat Bot and getting the API token

Here is a step-by-step guide to obtaining a Slack API token:

- Create a Slack App:
    - Go to the Slack API website: https://api.slack.com/apps
    - Click on "Create New App".
    - Fill out the necessary information for your app, such as the name and the Slack workspace where you want to install the app.
- Add Bot User:
    - Once your app is created, navigate to the "Bot Users" section under the "Features" tab in the sidebar.
    - Click on "Add a Bot User" and confirm the addition.
- Permissions for a Bot:
    - In the sidebar, go to "OAuth & Permissions".
    - Under "Scopes", add the necessary permissions for your app. For this simple bot, you'll need at least `channels:history`, `channels:join`, `channels:read`, `files:write`, `users.profile:read`, `users:read`, `chat:write`.
    - Save the changes.
- Install App to Workspace:
    - After adding permissions, scroll up to the top of the "OAuth & Permissions" page.
    - Click on the "Install App to Workspace" button.
    - Authorize the app to access your workspace.
- Retrieve Token:
    - Once the app is installed in your workspace, you'll be redirected to a page containing your OAuth Access Token.
    - Copy the OAuth Access Token. This token will be used as your APITOKEN value (to put into the `credentials.sh` file).

#### Find the Chat ID

To find the channel ID for some channel in Slack, you can follow these steps:

- Open Slack in a Web Browser
- Navigate to the Channel: find the channel in the sidebar or by using the search feature.
- View Channel Details: once you're in the channel, click on the channel name at the top to open the channel details.
- Get Channel ID: in the channel details, look for the "More" option (three vertical dots). Click on "More" and then select "Additional options". From the dropdown menu, choose "Copy link". The copied link will contain the channel ID at the end of the URL. It will look something like this: `https://yourworkspace.slack.com/archives/C1234567890`. The part after `/archives/` is the channel ID (`C1234567890` in this example). The channel id is supposed to be saved in the CHATID variable in the `credentials.sh` file.

#### Find the Bot User ID

To obtain the bot user ID or name, you typically need to retrieve this information from the Slack API. If you're using a bot token, you can call the auth.test method to get information about the bot user associated with the token. Here's how you can do it using curl: 
```
$ curl -X POST -H "Authorization: Bearer $APITOKEN" https://slack.com/api/auth.test
{"ok":true,"url":"https:\/\/xxxxxx.slack.com\/","team":"XXX","user":"somebotname","team_id":"A5B4C3D2G","user_id":"UXXABCDEFGH","bot_id":"BXXPQRSTUVWZ","is_enterprise_install":false}
```

This will return JSON data containing information about your bot user, including its user ID and name. In this example, the required id is `UXXABCDEFGH`. This value is supposed to be saved in the BOTID variable in the `credentials.sh` file.

#### Save the IDs

You have to save the information obtained during the steps made before. Put the APITOKEN value in the `creadentials.sh`. The same for values of `CHATID` and `BOTID` variables.

#### Add your bot to a Slack channel

You have to add the application that you created to the Slack channel that you are going to use. For this purpose, you open the channel in the interface, click on the name of channel on the top, in the area "Integration" you'll find the part named "Apps". Just add your application here. *NOTE:* adding the application to worspace doesn't work, you have to add your application to your channel!

## Bot commands

Currenty chat bot interaction script is able to handle two commands:

### `update`

Spelled: `/update @functestbot` for Telegram; `!update` for Slack.

Used to automatically start the `update.sh` script in the working directory to download the latest version of all scripts without a necessity of command-line actions on the target machine.

### `test`

Spelled: `/test ... @functestbot` for Telegram; `!test ...` for Slack.

Used to manually initiate test procedure for a selected target project branch.

- `test` -- with no args just starts a test procedure for a HEAD of default branch (branch name is set in `application.sh`; default set of test suites is set there as well).
- `test branch:<BRANCH>` -- starts the procedure for HEAD of a specific branch.
- `test branch:<BRANCH> suite:<SUITE1> suite:<SUITE2> suite:<SUITE3>` -- starts only selected suites for a specific branch. If some required suites are defined in `application.sh`, they will be added to this list automatically (in reversed order of the `TESTSUITE_REQUIRED_SUITES` value).
- `test suite:<SUITE> machine:<MACHINE>` -- will be handled on a certain machine (that means, if the `MACHINE` is defined as `TESTSUITE_HWCONF` values or is listed in the `TESTSUITE_AVAILABLE_HWCONFS`. If `TESTSUITE_HWCONF` is empty, only explicitly mentioned `machine:MACHINE` parameter results in actions.
- `test revision:<REVISION>` -- do test for a specific revision denoted by the commit hash (7 letters or more), but not for a head of some branch.


