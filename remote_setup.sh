#!/bin/bash

# Run this script to set up a remote server, so that when changes are pushed,
# the starter stack deploys.

mkdir nanome-starter-stack

git init --bare ~/nanome-starter-stack.git

ln post-receive ~/nanome-starter-stack.git/hooks/post-receive

chmod +x post-receive
