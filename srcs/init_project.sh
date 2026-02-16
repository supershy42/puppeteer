#!/bin/bash

set -euo pipefail

ENV_FILE="./.env"
BASE_DIR="${HOME}/supershy"
DATA_PATH="${BASE_DIR}/data"

echo "Preparing data directories at ${DATA_PATH}..."
mkdir -p "${BASE_DIR}"
rm -rf "${DATA_PATH}/chat" "${DATA_PATH}/game" "${DATA_PATH}/user"
mkdir -p "${DATA_PATH}/chat" "${DATA_PATH}/game" "${DATA_PATH}/user"

if [ ! -f "${ENV_FILE}" ]; then
    echo ".env file not found. Creating one..."
    if [ -f "./.env.example" ]; then
        cp "./.env.example" "${ENV_FILE}"
    else
        touch "${ENV_FILE}"
    fi
fi

if [ "$(uname)" = "Darwin" ]; then
    sed -i '' '/^DATA_PATH=/d' "${ENV_FILE}"
else
    sed -i '/^DATA_PATH=/d' "${ENV_FILE}"
fi

if [ -s "${ENV_FILE}" ] && [ "$(tail -c 1 "${ENV_FILE}" || true)" != "" ]; then
    echo "" >> "${ENV_FILE}"
fi
echo "DATA_PATH=${DATA_PATH}" >> "${ENV_FILE}"

echo "init_project completed."
