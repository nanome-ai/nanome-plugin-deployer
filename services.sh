#!/bin/bash
# Use Public ECR images to deploy services

cd $parent_path

REGISTRY_URI="public.ecr.aws/h7r1e4h2"

echo -e "\ndeploying services..."
for service in "${services[@]}"; do
    get_service_index $service
    if [ "${service_args[$service_index]}" == "" ]; then
        continue
    fi
    IMAGE_URI="$REGISTRY_URI/$service:latest"
    echo -n "pulling $service... "
    docker pull $IMAGE_URI >/dev/null
    docker tag $IMAGE_URI $service
    echo "done"

    echo -n "deploying $service... "
    arg_string="${service_args[$service_index]}"
    read -ra args <<< "$arg_string"
    source services/$service.sh "${args[@]}" 1>> "$logs/$service.log"
    echo "done"
done
