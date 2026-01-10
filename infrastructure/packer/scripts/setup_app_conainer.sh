#!/bin/bash
set -e

FULL_IMAGE_NAME="cr.yandex/$REGISTRY_ID/$IMAGE_NAME:$TAG"

# 1. Авторизация в YCR через метаданные ВМ
echo "Logging in to Yandex Container Registry..."
TOKEN=$(curl -s -H 'Metadata-Flavor: Google' 169.254.169.254 | jq -r .access_token)
echo $TOKEN | docker login --username iam --password-stdin cr.yandex

# 2. Скачиваем образ
echo "Pulling Docker image: $FULL_IMAGE_NAME"
docker pull "$FULL_IMAGE_NAME"

# 3. СОЗДАЕМ контейнер (но не запускаем его)
echo "Creating Docker container 'app'..."
docker create --name app -p 80:80 "$FULL_IMAGE_NAME"

# 4. Создаем systemd unit-файл
echo "Creating systemd service file..."
cat <<EOF | sudo tee /etc/systemd/system/app-docker.service
[Unit]
Description=ASP.NET App Docker Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a app
ExecStop=/usr/bin/docker stop app

[Install]
WantedBy=multi-user.target
EOF

# 5. Активируем и включаем сервис
echo "Enabling and starting systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable app-docker.service

# 6. Очистка (выходим из логина Docker, чтобы не хранить сессию)
echo "Logging out from YCR..."
docker logout cr.yandex
