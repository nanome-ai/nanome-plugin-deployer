#!/bin/bash
# Use Public ECR images to deploy plugins stack

echo "./deploy_from_images.sh $*" > redeploy.sh
chmod +x redeploy.sh

source base.sh

REGISTRY_URI="public.ecr.aws/h7r1e4h2"
REPO_NAMES=(
    "chemical-preview"
    "chemical-interactions"
    "chemical-properties"
    "coordinate-align"
    # "data-table"
    # "data-table-server"
    # "docking-autodock4"
    "docking-smina"
    "esp"
    "hydrogens"
    "minimization"
    "realtime-scoring"
    "rmsd"
    "smiles-loader"
    "structure-prep"
    "vault"
    "vault-server"
)

TAG="latest"

echo -e "\npulling plugin images..."
for REPO in "${REPO_NAMES[@]}"; do (
    IMAGE_URI="$REGISTRY_URI/$REPO:$TAG"
    echo -n "$REPO... "
    docker pull $IMAGE_URI >/dev/null
    docker tag $IMAGE_URI $REPO
    echo "done"
); done

echo -e "\ndeploying plugins..."
cd $INSTALL_DIRECTORY
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

echo -e "\ndone"
