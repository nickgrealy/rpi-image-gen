#!/bin/bash
# Build the Docker image, run rpi-image-gen inside it, then copy the .img out.
set -eu

BUILD_ID=${RANDOM}
RPI_BUILD_SVC="rpi_imagegen"
RPI_BUILD_USER="imagegen"

# rpi-image-gen config to build (filename relative to the repo root,
# resolved by rpi-image-gen's config search path)
RPI_CONFIG="camera-ap.yaml"

# Source directory containing the example layers and bdebstrap hooks
RPI_SOURCE_DIR="/home/${RPI_BUILD_USER}/rpi-image-gen/examples/camera-ap"

# image.name from config/camera-ap.yaml — determines the work/ subdirectory
RPI_IMAGE_NAME="camera-ap-image"

# Where to write the finished image on the host machine
OUTPUT_DIR="$(pwd)/output"
mkdir -p "${OUTPUT_DIR}"

ensure_cleanup() {
  echo "Cleaning up container..."
  CID=$(docker ps -a --filter "name=${RPI_BUILD_SVC}-${BUILD_ID}" --format "{{.ID}}" | head -n 1)
  if [ -n "${CID}" ]; then
    docker kill "${CID}" 2>/dev/null || true
    docker rm  "${CID}" 2>/dev/null || true
  fi
}
trap ensure_cleanup EXIT

echo "🔨 Building Docker image (${RPI_BUILD_SVC})..."
docker compose build ${RPI_BUILD_SVC}

echo "🚀 Running rpi-image-gen inside container..."
docker compose run \
  --name "${RPI_BUILD_SVC}-${BUILD_ID}" \
  --rm \
  "${RPI_BUILD_SVC}" \
  bash -c "
    cd /home/${RPI_BUILD_USER}/rpi-image-gen
    ./rpi-image-gen build -S ${RPI_SOURCE_DIR} -c ${RPI_CONFIG}
  "

echo "📦 Copying image to ${OUTPUT_DIR}..."
CID=$(docker ps -a --filter "name=${RPI_BUILD_SVC}-${BUILD_ID}" --format "{{.ID}}" | head -n 1)
docker cp \
  "${CID}:/home/${RPI_BUILD_USER}/rpi-image-gen/work/${RPI_IMAGE_NAME}/deploy/${RPI_IMAGE_NAME}.img" \
  "${OUTPUT_DIR}/${RPI_IMAGE_NAME}-$(date +%Y%m%d-%H%M).img"

echo "✅ Done → ${OUTPUT_DIR}/${RPI_IMAGE_NAME}-$(date +%Y%m%d-%H%M).img"
