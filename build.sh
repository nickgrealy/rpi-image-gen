#!/bin/bash
# Build the Docker image that contains rpi-image-gen and its dependencies.
set -eu

RPI_BUILD_SVC="rpi_imagegen"

echo "🔨 Building Docker image (${RPI_BUILD_SVC})..."
docker compose build ${RPI_BUILD_SVC}
echo "✅ Docker image built. Run ./build-and-run.sh to generate the RPi image."
