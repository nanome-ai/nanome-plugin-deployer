#!/bin/bash
# Build images from source to deploy plugins stack

source base.sh

mkdir -p $INSTALL_DIRECTORY/source
cd $INSTALL_DIRECTORY/source
for plugin_name in "${plugins[@]}"; do (
    echo -e "\n$plugin_name"
    if [ ! -d "$plugin_name" ] || [ ! -d "$plugin_name/.git" ]; then
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

    get_plugin_index $plugin_name
    arg_string="${args[@]} ${plugin_args[$plugin_index]}"
    read -ra args <<< "$arg_string"

    echo -n "  deploying... "
    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin_name.log"
    echo "done"
); done

start_nginx_if_needed
start_services_if_needed
echo -e "\ndone"
