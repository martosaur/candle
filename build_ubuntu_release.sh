#!/bin/bash
docker build -t candle-builder:latest --build-arg ADMIN_PASSWORD=$1 .

mkdir -p ./_build/ubuntu/rel

docker run --rm \
    --mount type=bind,source="$(pwd)"/_build/ubuntu/rel,destination=/app/_build/prod/rel \
    candle-builder:latest