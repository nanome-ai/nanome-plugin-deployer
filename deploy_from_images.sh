#!/bin/bash
# Use Public ECR images to deploy plugins stack

source base.sh

REGISTRY_URI="public.ecr.aws/h7r1e4h2"
REPO_NAMES=(
    "antibodies"
    "chemical-interactions"
    "chemical-preview"
    "chemical-properties"
    "conformer-generator"
    "coordinate-align"
    "cryoem"
    "data-table"
    "data-table-server"
    # "docking-autodock4"
    "docking-smina"
    "esp"
    "high-quality-surfaces"
    "hydrogens"
    "merge-as-frames"
    "minimization"
    "realtime-scoring"
    "rmsd"
    "smiles-loader"
    "superimpose-proteins"
    "structure-prep"
    "vault"
    "vault-server"
)

TAG="latest"

echo -e "\npulling plugin images..."
for REPO in "${REPO_NAMES[@]}"; do (
    skip=1
    for plugin in "${plugins[@]}"; do
        if [[ $REPO = $plugin* ]]; then
            skip=0
        fi
    done
    if [ $skip == 1 ]; then
        continue
    fi
    IMAGE_URI="$REGISTRY_URI/$REPO:$TAG"
    echo -n "$REPO... "
    docker pull $IMAGE_URI >/dev/null
    docker tag $IMAGE_URI $REPO
    echo "done"
); done

echo -e "\ndeploying plugins..."
mkdir -p $INSTALL_DIRECTORY/scripts
cd $INSTALL_DIRECTORY/scripts
for plugin_name in "${plugins[@]}"; do (
    echo -n "$plugin_name... "
    if [ -d "$plugin_name" ]; then
        rm -rf $plugin_name/*
    else
        mkdir -p $plugin_name
    fi

    cd $plugin_name
    wget -q https://raw.githubusercontent.com/nanome-ai/plugin-$plugin_name/master/docker/deploy.sh
    chmod +x deploy.sh

    get_plugin_index $plugin_name
    arg_string="${args[@]} ${plugin_args[$plugin_index]}"
    read -ra args <<< "$arg_string"

    ./deploy.sh "${args[@]}" 1>> "$logs/$plugin_name.log"
    echo "done"
); done

start_nginx_if_needed
start_services_if_needed
echo -e "\ndone"
