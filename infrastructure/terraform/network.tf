# ===== VPC =====
resource "yandex_vpc_network" "app_vpc" {
  name        = "app-vpc"
  description = "Main VPC for ASP.NET application"
  folder_id   = var.folder_id
}

# NAT GATEWAY
# NAT Gateway дает приватным подсетям выход в интернет (egress)
resource "yandex_vpc_gateway" "nat_gateway" {
  name      = "nat-gateway"
  folder_id = var.folder_id

  shared_egress_gateway {}
}

# ROUTE TABLE
# Таблица маршрутизации для приватных подсетей:
# весь трафик в интернет (0.0.0.0/0) отправляем через NAT Gateway
resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-route-table"
  folder_id  = var.folder_id
  network_id = yandex_vpc_network.app_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# ===== SUBNETS =====
# Private подсеть (ASP.NET приложение)
# Приватная подсеть выходит в интернет через NAT (route_table_id)
resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private-subnet"
  description    = "Private subnet for ASP.NET app (egress via NAT)"
  folder_id      = var.folder_id
  network_id     = yandex_vpc_network.app_vpc.id
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# Database подсеть (PostgreSQL)
# Тоже приватная, тоже с выходом через NAT (если вдруг БД нужно тянуть обновления/пакеты)
resource "yandex_vpc_subnet" "db_subnet" {
  name           = "db-subnet"
  description    = "Private subnet for database (egress via NAT)"
  folder_id      = var.folder_id
  network_id     = yandex_vpc_network.app_vpc.id
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}