#!/bin/bash

directory="plugins"
interactive=0
args=()
plugins=(
    "chemical-properties"
    "docking"
    "realtime-scoring"
    "rmsd"
    "structure-prep"
    "vault"
)
plugin_args=()
keyfile=""
github_url="https://github.com/nanome-ai/plugin-"

usage() {
    cat <<EOM

$0 [options]

    -i or --interactive
        Interactive mode

    -a <address> or --address <address>
        NTS address plugins connect to

    -p <port> or --port <port>
        NTS port plugins connect to

    -k <file> or --key <file>
        Key file for plugins to use when connecting to NTS

    -d <directory> or --directory <directory>
        Directory containing plugins

    --plugin <plugin-name> [args]
        Additional args for a specific plugin

EOM
}

plugin_index=0
get_plugin_index() {
    for i in "${!plugins[@]}"; do
        if [ "$1" == "${plugins[$i]}" ]; then
            plugin_index=$i
        fi
    done
}

parse_plugin_args() {
    while [ "$1" == "--plugin" ]; do
        shift
        plugin_name="$1"
        shift
        get_plugin_index $plugin_name
        plugin_args[$plugin_index]=""
        while [ $# -gt 0 ] && [ "$1" != "--plugin" ]; do
            plugin_args[$plugin_index]+="$1 "
            shift
        done
    done
}

echo -e "Nanome Starter Stack Deployer"

if [ $# -eq 0 ]; then
    interactive=1
fi

while [ $# -gt 0 ]; do
    case $1 in
        -i | --interactive )
            shift
            interactive=1
            break
            ;;
        -a | --address )
            shift
            args+=("-a" $1)
            ;;
        -p | --port )
            shift
            args+=("-p" $1)
            ;;
        -k | --key )
            shift
            args+=("-k" `basename $1`)
            keyfile="$1"
            ;;
        -d | --directory )
            shift
            directory=$1
            ;;
        --plugin )
            parse_plugin_args $*
            break
            ;;
        -h | --help )
            usage
            exit
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

if [ $interactive == 1 ]; then
    echo ""
    args=()
    read -p "Plugin directory?  (plugins): " directory
    directory=${directory:-"plugins"}
    read -p "NTS address?     (127.0.0.1): " address
    address=${address:-"127.0.0.1"}
    args+=("-a" $address)
    read -p "NTS port?             (8888): " port
    if [ -n "$port" ]; then
        args+=("-p" $port)
    fi
fi

if [ ! -d "$directory" ]; then
    mkdir -p $directory
fi

mkdir -p logs
logs=`(cd logs; pwd)`

cd $directory
for plugin in "${plugins[@]}"; do (
    echo -e "\n$plugin"
    if [ ! -d "$plugin" ]; then
        echo -n "  cloning... "
        git clone -q "$github_url$plugin" $plugin
        echo "done"
    fi

    if [ -n "$keyfile" ]; then
        cp "$keyfile" "$plugin/`basename $keyfile`"
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
