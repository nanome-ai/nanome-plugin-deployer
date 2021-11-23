# Arg parsing and preprocessing used by both deploy.sh and remote_deploy.sh

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
default_install_directory="$parent_path/plugins"

interactive=0
args=()

plugins=(
    "2d-chemical-preview"
    "chemical-interactions"
    "chemical-properties"
    "coordinate-align"
    "docking"
    "esp"
    "hydrogens"
    "minimization"
    "realtime-scoring"
    "rmsd"
    "structure-prep"
    "vault"
)
plugin_args=()
key=""
github_url="https://github.com/nanome-ai/plugin-"

usage() {
    cat << EOM
$0 [options]

    -i or --interactive
        Interactive mode

    -a <address> or --address <address>
        NTS address plugins connect to

    -p <port> or --port <port>
        NTS port plugins connect to

    -k <key> or --key <key>
        Key file or string for plugins to use when connecting to NTS

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
else
    echo "./deploy.sh $*" > redeploy.sh
    chmod +x redeploy.sh
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
            key=$1
            ;;
        -d | --directory )
            shift
            INSTALL_DIRECTORY=$1
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
    read -p "Plugin directory?  (plugins): " INSTALL_DIRECTORY
    INSTALL_DIRECTORY=${INSTALL_DIRECTORY:-$default_install_directory}
    read -p "NTS address?     (127.0.0.1): " address
    address=${address:-"127.0.0.1"}
    args+=("-a" $address)
    read -p "NTS port?             (8888): " port
    if [ -n "$port" ]; then
        args+=("-p" $port)
    fi
fi

if [ ! -d "$INSTALL_DIRECTORY" ]; then
    echo "Directory $INSTALL_DIRECTORY does not exist"
    mkdir -p $INSTALL_DIRECTORY
fi

if [ -n "$key" ]; then
    if [ -f "$key" ]; then
        key=`cat "$key" | tr -d [:space:]`
    fi
    args+=("-k" $key)
fi

mkdir -p logs
logs=`(cd logs; pwd)`

echo -n "pulling base image... "
docker pull nanome/plugin-env >/dev/null
echo "done"