#!/usr/bin/env bash

echo "Installing frontend npm dependencies..."
docker run --rm -u "$(id -u)" -v "$(pwd)/frontend:/app" -w "/app" node:alpine npm install

if ! [[ -f docker-compose.yml ]];
then
  echo "ERROR: docker-compose.yml not found"
  echo "Copy docker-compose.yml.dist removing the '.dist' extension"
  echo "  substitute <STORAGE_BUCKET> with the corresponding development S3 bucket and try again"
else
  echo "Building docker images..."
  docker-compose build
fi