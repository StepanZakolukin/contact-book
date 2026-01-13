resource "yandex_lb_target_group" "app_target_group" {
  name      = "app-target-group"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.app_servers
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }

  depends_on = [
    yandex_compute_instance.app_servers
  ]
}

resource "yandex_lb_network_load_balancer" "app_nlb" {
  name = "app-nlb"
  type = "external"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "https-listener"
    port = 443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_target_group.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 5000
        path = "/health"
      }
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 1
      interval            = 2
    }
  }
}

resource "yandex_vpc_address" "nlb_external_ip" {
  name = "nlb-external-ip"

  external_ipv4_address {
    zone_id = var.default_availability_zone
  }
}

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

resource "yandex_compute_instance" "app_servers" {
  count       = var.app_replica_count
  name        = "app-server-${count.index + 1}-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"
  zone        = element(var.availability_zones, count.index % length(var.availability_zones))

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

  # Динамически выбираем подсеть в зависимости от зоны
  network_interface {
    subnet_id = element([
      yandex_vpc_subnet.private_subnet_a.id,
      yandex_vpc_subnet.private_subnet_b.id,
      yandex_vpc_subnet.private_subnet_c.id
    ], count.index % length(var.availability_zones))
    nat       = true
    security_group_ids = [yandex_vpc_security_group.app_sg.id]
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_key}"
    
    user-data = <<-EOF
      #!/bin/bash
      
      # Добавляем hostname для идентификации реплики
      echo "app-server-${count.index + 1}" > /etc/hostname
      hostname "app-server-${count.index + 1}"
      
      DB_IP=${yandex_compute_instance.database.network_interface[0].ip_address}
      POSTGRES_PASSWORD=${var.postgres_pwd}
      ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa_keys.access_key}
      SECRET_KEY=${yandex_iam_service_account_static_access_key.sa_keys.secret_key}
      BUCKET_NAME=${yandex_storage_bucket.bucket.bucket}
      
      # Останавливаем старый контейнер
      docker stop app || true
      docker rm app || true
      
      # Запускаем приложение с уникальным идентификатором реплики
      docker run -d \
        --name app \
        --restart unless-stopped \
        --hostname app-server-${count.index + 1} \
        -e ConnectionStrings__DefaultConnection="Host=$${DB_IP};Port=5432;Database=postgres;Username=postgres;Password=$${POSTGRES_PASSWORD}" \
        -e YandexS3__AccessKey="$${ACCESS_KEY}" \
        -e YandexS3__SecretKey="$${SECRET_KEY}" \
        -e YandexS3__BucketName="$${BUCKET_NAME}" \
        -e ASPNETCORE_ENVIRONMENT="Production" \
        -e REPLICA_ID="${count.index + 1}" \
        -p 5000:8080 \
        cr.yandex/${var.registry_id}/${var.app_image_name}:1.0
      
      # Создаем health check эндпоинт с информацией о реплике
      sleep 5
      
      # Проверяем запуск
      echo "Rеплика ${count.index + 1} запущена в зоне $(hostname)"
      echo "Внутренний IP: $(hostname -I | awk '{print $1}')"
      echo "Внешний IP: $(curl -s ifconfig.me)"
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