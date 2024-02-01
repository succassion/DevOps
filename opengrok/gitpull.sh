#!/bin/sh
# Fix crontab error 
# apt install postfix
# set local

# vi /etc/crontab
# 0 */4 * * * root /home/admin/opengrokdata/gitpull.sh

# Colors
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[34m"
COLOR_END="\e[0m"

# Setting
GIT_USER="" # Git User
GIT_ADDR="" # Git Address
GIT_PORT="" # Git Port
repos="     
"           # Repository name

MAIN_PATH=/home/admin/opengrokdata
BASIC_PATH=$MAIN_PATH/source

if [ ! -d "$BASIC_PATH" ]; then
  echo "$COLOR_RED This BASIC PATH NOT exist. New Creste. $COLOR_END"
  mkdir -p $BASIC_PATH
fi

for re in $repos
do
  if [ ! -d "$BASIC_PATH/$re/.git" ]; then
    cd $MAIN_PATH/source/
    git clone ssh://$GIT_USER@$GIT_ADDR:$GIT_PORT/$re # If need, '&& scp -p -P $GIT_PORT $GIT_USER@$GIT_ADDR:hooks/commit-msg $re/.git/hooks/'
  else
    cd $MAIN_PATH/source/$re
    GIT_RESULT=$(git pull)
    echo "$COLOR_GREEN$re git $COLOR_END$GIT_RESULT"
  fi  
done
