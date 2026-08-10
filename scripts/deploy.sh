#!/bin/bash

set -e

IMAGE=$1

echo "Deploying $IMAGE"

docker pull "$IMAGE"

docker stop devops-app || true
docker rm devops-app || true

docker run -d \
  --name devops-app \
  -p 8080:80 \
  "$IMAGE"

echo "Deployment completed"