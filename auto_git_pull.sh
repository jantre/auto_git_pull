#!/bin/bash
# Description: Simple bash script you can run every minute in cron
#              to automatically pull the current branch from the remote.
# NOTE: This script assumes the branch you are pulling has the upstream set.
#       To set the upstream run;
#         git branch --set-upstream-to=origin/<branch> <local_branch>



LOCK_FILE='/tmp/auto_git_pull.lock'
DOCROOT='/var/www/replace_me'
LOG_FILE='/var/log/auto_git_pull.log'


# This function will automatically get called to handle proper shutdown
function shutdown () {
 # Remove the lock file.
 rm -f $LOCK_FILE
}

# If we're already running, just exit to prevent process overlap
if [ -f $LOCK_FILE ]
then
 echo `date` >> $LOG_FILE
 echo "`basename $0` is already running\n" | tee $LOG_FILE
 exit 1
fi


# Call the shutdown function on EXIT, TERMINATE and INTERRUPT signal
trap shutdown EXIT TERM INT

# create the lock file
touch $LOCK_FILE

# Check if the log file exists
if [ ! -f $LOG_FILE ]
then
 echo "WARNING: $LOG_FILE DOES NOT EXIST\n"| tee $LOG_FILE
 exit 1
fi

# Check if the log file is writeable
if [ ! -w $LOG_FILE ]
then
 echo "WARNING: `whoami` DOES NOT HAVE WRITE ACCESS TO $LOG_FILE\n" | tee $LOG_FILE
 exit 1
fi


#make sure the user has write access to the specified DOCROOT
if [ ! -w $DOCROOT ]
then
 echo "`whoami` does not have permission to $DOCROOT\n" | tee $LOG_FILE
 exit 1
fi

cd $DOCROOT

# first we need to run git fetch so that we can be aware of the local branch status in regards to origin.
/usr/bin/git fetch

# grepping for keyword 'behind' out of git status, which would tell us if our local branch is behind origin.
/usr/bin/git status | grep behind
RESULT=`echo $?`

# if the local branch is not behind then remove the exit.
if [ "$RESULT" != "0" ]
then
 exit $RESULT
fi

# There is something to pull
echo `date` >> $LOG_FILE
/usr/bin/git pull >> $LOG_FILE 2>&1
echo "" >> $LOG_FILE
