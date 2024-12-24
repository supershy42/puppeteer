#!/bin/bash

ENV_FILE="srcs/.env"

# Detect OS and set base directory for data storage
if [ "$(uname)" == "Darwin" ]; then
    BASE_DIR="/Users/$USER/data"
else
    BASE_DIR="/var/lib/supershy/data"
fi

# Ensure DATA_PATH exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Creating data directories..."
    sudo mkdir -p $BASE_DIR/user
    sudo mkdir -p $BASE_DIR/chat
    sudo mkdir -p $BASE_DIR/game
    # Adjust permissions
    sudo chown -R $USER:$USER $BASE_DIR
    echo "Data directories created successfully!"
else
    echo "Data directories already exist at $BASE_DIR."
fi

# Update or create the .env file
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env file..."
    touch "$ENV_FILE"
fi

if grep -q "DATA_PATH=" "$ENV_FILE"; then
    sed -i.bak "/^DATA_PATH=/c\DATA_PATH=$BASE_DIR" "$ENV_FILE"
else
    echo "DATA_PATH=$BASE_DIR" >> "$ENV_FILE"
fi

echo ".env file updated with DATA_PATH=$BASE_DIR."