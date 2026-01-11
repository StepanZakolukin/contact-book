resource "yandex_compute_instance" "app_server" {
  name = "app_server-${formatdate("YYYYMMDD", timestamp())}"
  description = "VM с ASP.NET приложением"

  resources {
    cores  = 2   # Кол-во ядер
    memory = 2   # Оперативная память в ГБ
  }

  boot_disk {
    initialize_params {
      image_id = var.app_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "yandex_compute_instance" "database" {
  name = "database-${formatdate("YYYYMMDD", timestamp())}"
  description = "VM с базой данных для ASP.NET приложения"

  resources {
    cores  = 2   # Кол-во ядер
    memory = 2   # Оперативная память в ГБ
  }

  boot_disk {
    initialize_params {
      image_id = var.database_image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.db_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }

  lifecycle {
    ignore_changes = [name]
  }
}
