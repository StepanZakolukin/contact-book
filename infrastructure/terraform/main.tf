resource "yandex_compute_instance" "database" {
  name = "database-${formatdate("YYYYMMDD", timestamp())}"
  platform_id = "standard-v3"

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
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_key}"
    user-data = <<-EOF
      #cloud-config
      runcmd:
        - [ systemctl, start, docker ]
        - [ systemctl, enable, docker ]
        - [ mkdir, -p, /var/lib/postgresql/data ]
        - [ chmod, 777, /var/lib/postgresql/data ]
        - [ docker, run, -d, --name, postgres, --restart, always, -e, POSTGRES_PASSWORD=${var.postgres_pwd}, -p, 5432:5432, -v, /var/lib/postgresql/data:/var/lib/postgresql/data, postgres:16-alpine ]
    EOF
  }

  lifecycle {
    ignore_changes = [name]
  }
}