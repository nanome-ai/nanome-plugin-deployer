#!/bin/bash
# Use Public ECR images to deploy plugins stack
source base.sh

echo "./deploy_from_images.sh $*" > redeploy.sh

REGISTRY_URI="public.ecr.aws/h7r1e4h2"
REPO_NAMES=(
    "chemical-interactions"
    "chemical-preview"
    "chemical-properties"
    "coordinate-align"
    # "docking-autodock4"
    "docking-smina"
    "esp"
    "hydrogens"
    "minimization"
    "realtime-scoring"
    "rmsd"
    "structure-prep"
    # "vault"
    # "vault-server"
)

TAG="latest"
arg_string="${args[@]} ${plugin_args[$plugin_index]}"
echo $
echo $arg_string
for REPO in "${REPO_NAMES[@]}"; do(
    image_uri="$REGISTRY_URI/$REPO:$TAG"

    if [ -n "$(docker ps -aqf name=$REPO$)" ]; then
        echo "removing existing container"
        docker rm -f $REPO
    fi
    docker run -d --name $REPO $image_uri python run.py $arg_string
);done

# Deploy vault and vault server
vault_name="vault"
vault_server_name="vault-server"
vault_network_name="vault-network"

vault_image_uri="$REGISTRY_URI/$vault_name:$TAG"
vault_server_image_uri="$REGISTRY_URI/$vault_server_name:$TAG"

if [ -n "$(docker ps -aqf name=$vault_name$)" ]; then
    echo "removing existing container"
    docker rm -f $vault_name
fi

if [ -n "$(docker ps -aqf name=$vault_server_name)" ]; then
    echo "removing existing container"
    docker rm -f $vault_server_name
fi

if [ -z "$(docker network ls -qf name=$vault_network_name)" ]; then
    echo "creating network"
    docker network create --driver bridge $vault_network_name
fi

if [ -z "$(docker ps -qf name=vault-converter)" ]; then
    echo "starting vault-converter"
    docker run --rm -d \
    --name vault-converter \
    --network $vault_network_name \
    --env DISABLE_GOOGLE_CHROME=1 \
    --env MAXIMUM_WAIT_TIMEOUT=60 \
    --env DEFAULT_WAIT_TIMEOUT=60 \
    thecodingmachine/gotenberg:6 2>&1
fi

DEFAULT_PORT=80
SERVER_PORT=80
PORT=


# generate random hex api key
API_KEY=`od -vN "16" -An -tx1 /dev/urandom | tr -d " \n"`

while [ -n "$1" ]; do
    case $1 in
        --https | -s | --ssl-cert )
            if [ -z "$PORT" ]; then
                PORT=443
            fi
            SERVER_PORT=443
            ;;
        -w | --web-port )
            shift
            PORT=$1
            ;;
    esac
    shift
done

if [ -z "$PORT" ]; then
    PORT=$DEFAULT_PORT
fi

docker run -d \
--name vault \
--restart unless-stopped \
--network $vault_network_name \
--env no_proxy=$vault_server_name \
--env NO_PROXY=$vault_server_name \
-e ARGS="$ARGS --api-key $API_KEY" \
$vault_image_uri

docker run -d \
--name $vault_server_name \
--restart unless-stopped \
--network $vault_network_name \
--env no_proxy=vault-converter \
--env NO_PROXY=vault-converter \
-p $PORT:$SERVER_PORT \
-e ARGS="$ARGS --api-key $API_KEY" \
-v vault-volume:/root \
$vault_server_image_uri
