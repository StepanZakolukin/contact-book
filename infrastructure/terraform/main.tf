resource "yandex_iam_service_account" "sa" {
  name        = var.service_account_name
  description = "Service account for Object Storage access"
}

resource "yandex_iam_service_account_static_access_key" "sa_keys" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_role" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_storage_bucket" "bucket" {
  bucket = "contact-book"
  folder_id = var.folder_id
  default_storage_class = "STANDARD"
  depends_on = [
    yandex_resourcemanager_folder_iam_member.sa_storage_role
  ]
}

resource "yandex_compute_instance" "app_server" {
  name        = "app-server-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"
  zone        = var.default_availability_zone

  depends_on = [
    yandex_compute_instance.database,
    yandex_iam_service_account_static_access_key.sa_keys,
    yandex_storage_bucket.bucket
  ]

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_image_id
      type     = "network-ssd"
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_key}"
    
    user-data = <<-EOF
      #!/bin/bash
      
      DB_IP=${yandex_compute_instance.database.network_interface[0].ip_address}
      POSTGRES_PASSWORD=${var.postgres_pwd}
      ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa_keys.access_key}
      SECRET_KEY=${yandex_iam_service_account_static_access_key.sa_keys.secret_key}
      BUCKET_NAME=${yandex_storage_bucket.bucket.bucket}
      
      docker stop app || true
      docker rm app || true
      
      docker run -d \
        --name app \
        --restart unless-stopped \
        -e ConnectionStrings__DefaultConnection="Host=$${DB_IP};Port=5432;Database=postgres;Username=postgres;Password=$${POSTGRES_PASSWORD}" \
        -e YandexS3_AccessKey="$${ACCESS_KEY}" \
        -e YandexS3_SecretKey="$${SECRET_KEY}" \
        -e YandexS3_BucketName="$${BUCKET_NAME}" \
        -p 80:8080 \
        -p 443:443 \
        cr.yandex/${var.registry_id}/${var.app_image_name}:latest
    EOF
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "yandex_compute_instance" "database" {
  name = "database-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"
  zone        = var.default_availability_zone

  resources {
    cores  = 2
    memory = 2
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = var.database_image_id
      type     = "network-ssd"
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.db_subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.db_sg.id]
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_key}"
    
    user-data = <<-EOF
      #!/bin/bash
      
      exec > /var/log/postgres-setup.log 2>&1
      echo "=== Начало настройки PostgreSQL ==="
      date
      
      # Устанавливаем Docker если нет
      if ! command -v docker &> /dev/null; then
        echo "Установка Docker..."
        apt-get update
        apt-get install -y docker.io
      fi
      
      # Запускаем Docker
      echo "Запуск Docker..."
      systemctl start docker
      systemctl enable docker
      sleep 3
      
      # Останавливаем и удаляем старый контейнер
      echo "Очистка старого контейнера..."
      docker stop postgres || true
      docker rm postgres || true
      
      # Чистим директорию данных (осторожно - удалит все данные!)
      echo "Очистка директории данных..."
      rm -rf /var/lib/postgresql/data/*
      rm -rf /var/lib/postgresql/data/.* 2>/dev/null || true
      
      # Создаем чистую директорию
      mkdir -p /var/lib/postgresql/data
      chown -R 999:999 /var/lib/postgresql/data  # PostgreSQL в контейнере использует UID 999
      chmod 700 /var/lib/postgresql/data  # Важно для безопасности PostgreSQL
      
      # Запускаем PostgreSQL
      echo "Запуск PostgreSQL контейнера..."
      docker run -d \
        --name postgres \
        --restart unless-stopped \
        -e POSTGRES_PASSWORD=${var.postgres_pwd} \
        -e POSTGRES_DB=postgres \
        -p 0.0.0.0:5432:5432 \
        -v /var/lib/postgresql/data:/var/lib/postgresql/data \
        postgres:16-alpine
      
      echo "Ожидание запуска PostgreSQL (30 секунд)..."
      sleep 30
      
      echo "Статус контейнера:"
      docker ps
      
      echo "Логи PostgreSQL:"
      docker logs postgres --tail 20
      
      echo "=== Настройка PostgreSQL завершена ==="
      date
    EOF
  }

  lifecycle {
    ignore_changes = [name]
  }
}