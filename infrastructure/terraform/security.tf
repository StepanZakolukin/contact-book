# SECURITY GROUP: ASP.NET приложение
resource "yandex_vpc_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for ASP.NET application (NLB targets)"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.app_vpc.id

  # Разрешить трафик из всех подсетей приложения
  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.0.2.0/24", "10.0.12.0/24", "10.0.22.0/24"]
    port           = 80
    description    = "Allow inter-instance communication in all app subnets"
  }

  # Исходящий к базе данных
  egress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port           = 5432
    description    = "Allow outbound to PostgreSQL"
  }

  # Исходящий: в интернет
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow outbound to internet (via NAT)"
  }
}

# ВАЖНО: health checks от Network Load Balancer
# SG нельзя назначить на listener NLB, поэтому health-check трафик разрешаем на VM-таргетах.
resource "yandex_vpc_security_group_rule" "app_healthchecks" {
  security_group_binding = yandex_vpc_security_group.app_sg.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 80
  predefined_target      = "loadbalancer_healthchecks"
  description            = "Allow NLB health checks to app port (TCP)"
}

# SECURITY GROUP: PostgreSQL
resource "yandex_vpc_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for PostgreSQL database"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.app_vpc.id

  # Входящий только от приложения
  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.0.2.0/24"]
    port           = 5432
    description    = "Allow PostgreSQL from app subnet"
  }
}
