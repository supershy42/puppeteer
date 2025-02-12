#!/bin/bash

ENV_FILE="./.env"

# 현재 사용자와
CURRENT_USER=$(id -u)
CURRENT_GROUP=$(id -gn)

# 현재 프로젝트 디렉토리의 절대경로 가져오기
PROJECT_ROOT=$(pwd)

# OS에 따른 BASE_DIR 설정
if [ "$(uname)" == "Darwin" ]; then
    # macOS
    BASE_DIR="/Users/$USER/supershy"
else
    # Linux
    BASE_DIR="/home/$USER/supershy"
fi

# 기존 볼륨 삭제 처리
# if [ -d "$BASE_DIR" ]; then
#     echo "Deleting existing volumes..."
#     rm -rf "$BASE_DIR"
#     echo "Delete complete."

#     if [ -f "$ENV_FILE" ]; then
#         if [ "$(uname)" == "Darwin" ]; then
#             sed -i '' '/^DATA_PATH=/d' "$ENV_FILE"
#         else
#             sed -i '/^DATA_PATH=/d' "$ENV_FILE"
#         fi
#     else
#         echo ".env file not found. Skipping DATA_PATH removal."
#     fi
# fi

# DATA_PATH="${BASE_DIR}/data"

# # 볼륨 추가 처리
# if [ ! -d "$BASE_DIR" ]; then
#     echo "Adding volumes..."
#     mkdir -p $DATA_PATH/chat/
#     mkdir -p $DATA_PATH/game/
#     mkdir -p $DATA_PATH/user/

#     # BASE_DIR 디렉토리의 소유자를 현재 사용자로 변경
#     chown -R $CURRENT_USER:$CURRENT_GROUP $BASE_DIR
#     echo "Add complete."
# fi

# if [ -f "$ENV_FILE" ]; then
#     if [ "$(uname)" == "Darwin" ]; then
#         sed -i '' '/^DATA_PATH=/d' "$ENV_FILE"
#     else
#         sed -i '/^DATA_PATH=/d' "$ENV_FILE"
#     fi
# else
#     echo ".env file not found. Skipping DATA_PATH removal."
# fi

# .env 파일에 DATA_PATH 추가
# if ! grep -q "DATA_PATH=" "$ENV_FILE"; then
#     if [ -s "$ENV_FILE" ] && [ "$(tail -c 1 "$ENV_FILE" | wc -l)" -eq 0 ]; then
#         echo "" >> "$ENV_FILE"
#     fi
#     echo "DATA_PATH=$DATA_PATH" >> "$ENV_FILE"
# fi
