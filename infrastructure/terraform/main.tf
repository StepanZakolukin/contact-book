resource "yandex_compute_instance" "app_server" {
  name        = "app-server-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"
  zone        = var.zone

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

    docker-container-declaration = yamlencode({
      spec = {
        containers = [
          {
            image = "cr.yandex/${var.registry_id}/${var.app_image_name}:${var.app_image_tag}"
            name  = "app"
            env = [
              {
                name  = "ConnectionStrings__DefaultConnection"
                value = "Host=${yandex_compute_instance.database.network_interface.0.ip_address};Port=5432;Database=postgres;Username=postgres;Password=${var.postgres_pwd}"
              },
              {
                name  = "YandexS3_SecretKey"
                value = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
              },
              {
                name  = "YandexS3_AccessKey"
                value = yandex_iam_service_account_static_access_key.sa_static_key.access_key
              },
              {
                name  = "YandexS3_BucketName"
                value = yandex_storage_bucket.contact_book.bucket
              }
            ]
          }
        ]
      }
    })
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "yandex_compute_instance" "database" {
  name = "database-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
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
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_key}"
  }

  lifecycle {
    ignore_changes = [name]
  }
}
