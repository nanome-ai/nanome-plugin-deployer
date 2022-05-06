#!/bin/bash

if [ -z "$(docker network ls -qf name=nginx-proxy)" ]; then
    echo "creating network"
    docker network create nginx-proxy
fi

existing=$(docker ps -qf name=nginx-proxy)
if [ -n "$existing" ]; then
    echo "removing existing container"
    docker rm -f $existing
fi

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd -P)

docker create --rm \
--name nginx-proxy \
--net nginx-proxy \
-p 80:80 \
-p 443:443 \
-v $current_dir/certs:/etc/nginx/certs \
-v $current_dir/custom.conf:/etc/nginx/conf.d/custom.conf:ro \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
jwilder/nginx-proxy

docker network connect data-table-network nginx-proxy
docker network connect vault-network nginx-proxy

docker start nginx-proxy
