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
  ssh_username        = var.ssh_username
  use_ipv4_nat        = "true"
  image_description   = "Образ диска c PostgreSQL, работающим в docker-контейнере"
  source_image_id     = var.source_image_id
  image_name          = "postgresql-image"
  disk_type           = "network-ssd"
  zone                = var.default_availability_zone
}

source "yandex" "app_server" {
  folder_id           = var.folder_id
  ssh_username        = var.ssh_username
  use_ipv4_nat        = "true"
  image_description   = "Образ диска c приложением, работающим в docker-контейнере"
  source_image_id     = var.source_image_id
  image_name          = "app-server-image"
  disk_type           = "network-ssd"
  zone                = var.default_availability_zone
  service_account_id  = var.service_account_puller_id
}

build {
  sources  = [
    "source.yandex.postgresql",
    "source.yandex.app_server"
  ]

  provisioner "shell" {
    inline = ["sudo apt-get update"]
  }

  provisioner "shell" {
    only             = ["yandex.postgresql"]

    environment_vars = ["POSTGRES_PWD=${var.postgres_pwd}"]

    scripts          = "scripts/setup_postgres_container.sh"
  }

  provisioner "shell" {
    only = ["yandex.app_server"]

    environment_vars = [
      "REGISTRY_ID=${var.registry_id}",
      "IMAGE_NAME=${var.app_image_name}",
      "TAG=${var.app_image_tag}"
    ]

    script          = "scripts/setup_app_container.sh"
  }
}
