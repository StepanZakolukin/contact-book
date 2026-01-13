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
            image = "cr.yandex/${var.registry_id}/${var.app_image_name}:latest"
            name  = "app"
			env = [
				{
					name  = "ConnectionStrings__DefaultConnection"
					value = "Host=${yandex_compute_instance.database.network_interface.0.ip_address};Port=5432;Database=postgres;Username=postgres;Password=${var.postgres_pwd}"
				},
				{
					name  = "YandexS3_SecretKey"
					value = yandex_iam_service_account_static_access_key.sa_keys.secret_key
				},
				{
					name  = "YandexS3_AccessKey"
					value = yandex_iam_service_account_static_access_key.sa_keys.access_key
				},
				{
					name  = "YandexS3_BucketName"
					value = yandex_storage_bucket.bucket.bucket
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