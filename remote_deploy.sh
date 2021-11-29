#!/bin/bash
# Deploy starter stack in a way that enables updating via git push.

source base.sh

TEMPLATE_POST_RECEIVE_HOOK="$parent_path/plugin-post-receive.sh"

cd $INSTALL_DIRECTORY
for plugin_name in "${plugins[@]}"; do (
    echo -e "\n$plugin_name"
    github_url="$github_url$plugin_name"

    GIT_DIR=$PWD/$plugin_name.git
    WORK_TREE=$PWD/$plugin_name

    if [ ! -d $GIT_DIR ]; then
        echo -n "Cloning $github_url to $GIT_DIR" 
        git clone --bare -q $github_url $GIT_DIR
    fi
    if [ ! -d $WORK_TREE ]; then
        mkdir -p $WORK_TREE
    fi
    echo "checking out"
    git --work-tree=$WORK_TREE --git-dir=$GIT_DIR checkout -f master
    echo "done"

    # Default branch is usually master, but sometimes it's main.
    DEFAULT_BRANCH="$(cd $GIT_DIR && git remote show origin | sed -n '/HEAD branch/s/.*: //p')"    

    # copy template post-receive hook into git repo, and replace with correct values.
    POST_RECEIVE_HOOK=$GIT_DIR/hooks/post-receive
    cp $TEMPLATE_POST_RECEIVE_HOOK $POST_RECEIVE_HOOK
    sed -i "s|{{WORK_TREE}}|$WORK_TREE|" $POST_RECEIVE_HOOK
    sed -i "s|{{GIT_DIR}}|$GIT_DIR|" $POST_RECEIVE_HOOK
    sed -i "s|{{DEFAULT_BRANCH}}|$DEFAULT_BRANCH|" $POST_RECEIVE_HOOK
    chmod +x $POST_RECEIVE_HOOK

    # Build docker container
    cd $WORK_TREE/docker
    echo -n "  building... "
    ./build.sh -u 1>> "$logs/$plugin_name.log"
    echo "done"

    get_plugin_index $plugin_name
    arg_string="${args[@]} ${plugin_args[$plugin_index]}"
    read -ra args <<< "$arg_string"

    # Deploy container
    echo -n "  deploying... "
    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin_name.log"
    echo "done"

); done

echo -e "\ndone"
