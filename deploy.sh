#!/bin/bash
source base.sh

cd $INSTALL_DIRECTORY
for plugin_name in "${plugins[@]}"; do (
    echo -e "\n$plugin_name"
    if [ ! -d "$plugin_name" ]; then
        echo -n "  cloning... "
        git clone -q "$github_url$plugin_name" $plugin_name
        echo "done"
    fi

    cd $plugin_name
    echo -n "  pulling... "
    git pull -q
    echo "done"

    cd docker
    echo -n "  building... "
    if ./build.sh -u 1>> "$logs/$plugin_name.log"; then
        echo "done"
    else
        echo "failed"
        continue
    fi

    arg_string="${args[@]} ${plugin_args[$plugin_name]}"
    read -ra args <<< "$arg_string"

    echo -n "  deploying... "
    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin_name.log"
    echo "done"
); done

echo -e "\ndone"
