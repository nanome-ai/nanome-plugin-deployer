#!/bin/bash
source base.sh

cd $directory
for plugin in "${plugins[@]}"; do (
    echo -e "\n$plugin"
    if [ ! -d "$plugin" ]; then
        echo -n "  cloning... "
        git clone -q "$github_url$plugin" $plugin
        echo "done"
    fi

    cd $plugin
    echo -n "  pulling... "
    git pull -q
    echo "done"
    cd docker
    echo -n "  building... "
    ./build.sh -u 1>> "$logs/$plugin.log"
    echo "done"

    get_plugin_index $plugin
    arg_string="${args[@]} ${plugin_args[$plugin_index]}"
    read -ra args <<< "$arg_string"

    echo -n "  deploying... "
    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin.log"
    echo "done"
); done

echo -e "\ndone"
