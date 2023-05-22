#!/bin/bash

existing=$(docker ps -aqf name=quickdrop)
if [ -n "$existing" ]; then
    echo "removing existing container"
    docker rm -f $existing
fi

PORT=80
PORT_SET=0
NGINX=0
ARGS=$*
DOCKER_ARGS=()

while [ -n "$1" ]; do
    case $1 in
        -https | --https )
            PORT=443
            DOCKER_ARGS+=(
                --env CERT_NAME=default
                --env VIRTUAL_PORT=443
                --env VIRTUAL_PROTO=https
            )
            ;;
        --nginx )
            NGINX=1
            ;;
        -port | --port )
            shift
            PORT=$1
            PORT_SET=1
            ;;
        -url | --url )
            shift
            DOCKER_ARGS+=(--env VIRTUAL_HOST=$1)
            ;;
    esac
    shift
done

if [ $NGINX -eq 1 ]; then
    if [ $PORT_SET -eq 1 ]; then
        echo "Error: --nginx and --port cannot be used together"
        exit 1
    fi

    if [ -z "$(docker ps -qf name=nginx-proxy)" ]; then
        echo "Error: nginx-proxy must be running to use --nginx"
        exit 1
    fi

    DOCKER_ARGS+=(--expose $PORT --network nginx-proxy)
else
    DOCKER_ARGS+=(-p $PORT:$PORT)
fi

docker run -d \
--name quickdrop \
--restart unless-stopped \
${DOCKER_ARGS[@]} \
quickdrop \
${ARGS[@]}
