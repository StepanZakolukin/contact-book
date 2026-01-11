packer {
  required_plugins {
    yandex = {
      version = "~> 1"
      source  = "github.com/hashicorp/yandex"
    }
  }
}

source "yandex" "postgresql" {
  folder_id           = var.folder_id
  subnet_id           = var.default_subnet_id
  disk_size_gb        = 15
  ssh_username        = var.ssh_username
  use_ipv4_nat        = "true"
  image_description   = "Образ диска c PostgreSQL, работающим в docker-контейнере"
  source_image_family = "container-optimized-image"
  image_name          = "postgresql-image"
  disk_type           = "network-ssd"
  zone                = var.default_availability_zone
  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_key}"

    docker-container-declaration = yamlencode({
      spec = {
        containers = [
          {
            image = "postgres:16-alpine"
            name  = "postgres"
            env = [
              {
                name  = "POSTGRES_PASSWORD"
                value = "${var.postgres_pwd}"
              }
            ]
            portBindings = [
              {
                containerPort = 5432
                hostPort      = 5432
              }
            ]
            volumeMounts = [
              {
                mountPath = "/var/lib/postgresql/data"
                name      = "postgres-data"
              }
            ]
          }
        ]
        volumes = [
          {
            name = "postgres-data"
            hostPath = {
              path = "/var/lib/postgresql/data"
            }
          }
        ]
      }
    })
  }
}

source "yandex" "app_server" {
  folder_id           = var.folder_id
  subnet_id           = var.default_subnet_id
  disk_size_gb        = 15
  ssh_username        = var.ssh_username
  use_ipv4_nat        = "true"
  image_description   = "Образ диска c приложением, работающим в docker-контейнере"
  source_image_family = "container-optimized-image"
  image_name          = "app-server-image"
  disk_type           = "network-ssd"
  zone                = var.default_availability_zone
  service_account_id  = var.service_account_puller_id
  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_key}"

    docker-container-declaration = yamlencode({
      spec = {
        containers = [
          {
            image = "cr.yandex/${var.registry_id}/${var.app_image_name}:${var.app_image_tag}"
            name  = "app"
            logConfig = {
              type = "json-file"
              options = {
                "max-size" = "10m"
                "max-file" = "3"
              }
            }
            securityContext = {
              privileged = false
            }
            tty = false
            stdin = false
            restartPolicy = "Always"
            portBindings = [
              {
                containerPort = 80
                hostPort      = 80
              }
            ]
          }
        ]
      }
    })
  }
}

build {
  sources = [
    "source.yandex.postgresql",
    "source.yandex.app_server"
  ]
}
