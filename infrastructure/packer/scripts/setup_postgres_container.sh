#!/bin/bash
set -e

# Настройки
DB_CONTAINER_NAME="postgres"
DB_IMAGE="postgres:16-alpine" # Используем alpine для экономии места

echo "Pulling PostgreSQL image..."
docker pull $DB_IMAGE

# 1. Создаем Docker Volume для данных (он станет частью образа диска)
echo "Creating postgres-data volume..."
docker volume create postgres-data

# 2. СОЗДАЕМ контейнер (без запуска)
# Мы передаем пароль здесь. При первом старте Postgres инициализирует базу в Volume.
echo "Creating container $DB_CONTAINER_NAME..."
docker create --name $DB_CONTAINER_NAME \
  -e POSTGRES_PASSWORD="${POSTGRES_PWD}" \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  $DB_IMAGE

# 3. Создаем systemd unit-файл
echo "Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/postgres-docker.service
[Unit]
Description=PostgreSQL Docker Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
# Используем -a (attach) для корректного сбора логов в journald
ExecStart=/usr/bin/docker start -a $DB_CONTAINER_NAME
ExecStop=/usr/bin/docker stop $DB_CONTAINER_NAME

[Install]
WantedBy=multi-user.target
EOF

# 4. Активируем сервис
sudo systemctl daemon-reload
sudo systemctl enable postgres-docker.service

echo "Postgres setup complete."
