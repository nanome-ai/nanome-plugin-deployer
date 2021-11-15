#!/bin/bash

# This script is called by the post-receive hook of the git repository.

ENV_FILE="/home/ec2-user/.env"
TARGET="/home/ec2-user/coordinate-align"
GIT_DIR="/home/ec2-user/coordinate-align.git"
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
                git --work-tree=$TARGET --git-dir=$GIT_DIR checkout -f $BRANCH
                $TARGET/docker/build.sh
                $TARGET/docker/deploy.sh -a $NTS_HOST -p $NTS_PORT
        else
                echo "Ref $ref received. Doing nothing: only the ${BRANCH} branch may be deployed on this server."
        fi
done
