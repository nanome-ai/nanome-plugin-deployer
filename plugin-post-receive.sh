#!/bin/bash

# This script is called by the post-receive hook of the git repository.

# deploy.sh replaces these placeholder values for each plugin.
ENV_FILE="$HOME/.env"
WORK_TREE="{{WORK_TREE}}"
GIT_DIR="{{GIT_DIR}}"
BRANCH="{{DEFAULT_BRANCH}}"

# Load environment variables from .env file, if it exists.
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
        echo "Ref $ref received. Deploying ${BRANCH} branch to environment..."
        git --work-tree=$WORK_TREE --git-dir=$GIT_DIR checkout -f $BRANCH
        $WORK_TREE/docker/build.sh
        cd $WORK_TREE/docker
        $WORK_TREE/docker/redeploy.sh
    else
        echo "Ref $ref received. Doing nothing: only the ${BRANCH} branch may be deployed on this server."
    fi
done
