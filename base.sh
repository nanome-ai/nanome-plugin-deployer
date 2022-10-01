# Arg parsing and preprocessing used by both deploy.sh and remote_deploy.sh

# on linux, buildkit not enabled by default. buildkit builds only relevant stages
export DOCKER_BUILDKIT=1

parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)
rename_path=$(echo "$parent_path" | sed 's/nanome-starter-stack/nanome-plugin-deployer/g')
if [ "$rename_path" != "$parent_path" ]; then
    echo "renaming directory to nanome-plugin-deployer"
    mv "$parent_path" "$rename_path"
    parent_path="$rename_path"
fi

INSTALL_DIRECTORY="$parent_path/plugins"

interactive=0
args=()

plugins=(
    "2d-chemical-preview"
    "chemical-interactions"
    "chemical-properties"
    "coordinate-align"
    "data-table"
    "docking"
    "esp"
    "high-quality-surfaces"
    "hydrogens"
    "merge-as-frames"
    "minimization"
    "realtime-scoring"
    "rmsd"
    "smiles-loader"
    "structure-prep"
    "superimpose-proteins"
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

    --remote-logging <y/n>
        Toggle whether or not logs should be forwarded to NTS

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

use_nginx=0
if [[ "$*" == *"--nginx"* ]]; then
    use_nginx=1
fi

start_nginx_if_needed() {
    if [ $use_nginx -eq 1 ]; then
        source $parent_path/nginx/start.sh
    fi
}

echo -e "Nanome Plugin Deployer"

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
            key=$1
            ;;
        --remote-logging )
            shift
            args+=("--remote-logging" $1)
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
    INSTALL_DIRECTORY=${INSTALL_DIRECTORY:-$INSTALL_DIRECTORY}
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
