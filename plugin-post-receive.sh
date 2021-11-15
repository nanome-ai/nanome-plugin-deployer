#!/bin/bash

# This script is called by the post-receive hook of the git repository.

PLUGIN_NAME="$1"

ENV_FILE="$HOME/.env"
WORK_DIR="$HOME/$PLUGIN_NAME"
GIT_DIR="$HOME/$PLUGIN_NAME.git"
BRANCH="master"

if [ -f $ENV_FILE ]
then
    echo "LOADING .env file"
    export $(cat $ENV_FILE | sed 's/#.*//g' | xargs)
fi


while read oldrev newrev ref
do
    # only checking out the master (or whatever branch you would like to deploy)
    if [ "$ref" = "refs/heads/$BRANCH" ];
    then
            echo "Ref $ref received. Deploying ${BRANCH} branch to production..."
            git --work-tree=$WORK_DIR --git-dir=$GIT_DIR checkout -f $BRANCH
            $WORK_DIR/docker/build.sh
            $WORK_DIR/docker/deploy.sh -a $NTS_HOST -p $NTS_PORT
    else
            echo "Ref $ref received. Doing nothing: only the ${BRANCH} branch may be deployed on this server."
    fi
done
