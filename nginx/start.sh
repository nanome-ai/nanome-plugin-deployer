#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script cannot be executed directly. Please use the deploy.sh script."
    exit 1
fi

port_arg=("-p $nginx_port:80")
if [ $use_https -eq 1 ]; then
    if [ $nginx_port_set -eq 0 ]; then
        nginx_port=443
    fi
    port_arg=("-p $nginx_port:443")
fi

if [ -z "$(docker network ls -qf name=nginx-proxy)" ]; then
    echo "creating network"
    docker network create nginx-proxy
fi

existing=$(docker ps -aqf name=nginx-proxy)
if [ -n "$existing" ]; then
    echo "removing existing container"
    docker rm -f $existing
fi

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd -P)

docker create \
--name nginx-proxy \
--net nginx-proxy \
--restart unless-stopped \
${port_arg[@]} \
-v $current_dir/certs:/etc/nginx/certs \
-v $current_dir/custom.conf:/etc/nginx/conf.d/custom.conf:ro \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
jwilder/nginx-proxy:1.6.4

docker network connect data-table-network nginx-proxy
docker network connect vault-network nginx-proxy

docker start nginx-proxy
