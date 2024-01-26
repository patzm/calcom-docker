#! /usr/bin/env bash

# Enable Docker BuildKit for better performance
export DOCKER_BUILDKIT=1
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Load all variables from the provided env file
ENV_FILE=${1}
if [ -z "$1" ]; then
    echo "Provide the path to the environment file used later in production."
    exit 1
elif [ -f ${ENV_FILE} ]; then
    echo "Loading variables from ${ENV_FILE}"
    export $(grep -v '^#' .env | xargs)
fi

DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DATABASE_HOST}/${POSTGRES_DB}"

DOMAIN="${NEXT_PUBLIC_WEBAPP_URL#https://}"
TAG="$(cd ${SCRIPT_DIR}/calcom; git describe --tags `git rev-list --tags --max-count=1`)"
IMAGE_NAME="registry.gitlab.com/patzm/calcom-docker/${DOMAIN}:${TAG}"
echo "Building image ${IMAGE_NAME}"

# Build the Docker image with the specified build arguments
docker build --progress=plain \
    --build-arg NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL} \
    --build-arg NEXT_PUBLIC_LICENSE_CONSENT=${NEXT_PUBLIC_LICENSE_CONSENT} \
    --build-arg CALCOM_TELEMETRY_DISABLED=${CALCOM_TELEMETRY_DISABLED} \
    --build-arg NEXTAUTH_SECRET=${NEXTAUTH_SECRET} \
    --build-arg CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY} \
    --build-arg DATABASE_URL=${DATABASE_URL} \
    -t ${IMAGE_NAME} .

# Push it to the registry
docker push ${IMAGE_NAME}

unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)

echo "Success!"
echo "Make sure to use the same environment variables when deploying this image."
