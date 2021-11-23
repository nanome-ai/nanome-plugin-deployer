#!/bin/bash
source base.sh

cd $INSTALL_DIRECTORY
for plugin_name in "${plugin_names[@]}"; do (
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
    ./build.sh -u 1>> "$logs/$plugin_name.log"
    echo "done"

    get_plugin_index $plugin_name
    arg_string="${args[@]} ${plugin_args[$plugin_index]}"
    read -ra args <<< "$arg_string"

    echo -n "  deploying... "
    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin_name.log"
    echo "done"
); done

echo -e "\ndone"
