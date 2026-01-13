variable "cloud_id" {
  type        = string
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  description = "ID директории в облаке"
}

variable "ssh_key" {
  type        = string
  description = "Публичный ssh ключ"
}

variable "app_image_id" {
  type        = string
  description = "ID образа диска приложения"
}

variable "database_image_id" {
  type        = string
  description = "ID образа диска базы данных"
}

variable "service_account_name" {
  type        = string
  description = "Имя сервисного аккаунта"
}

variable "registry_id" {
  description = "Yandex Container Registry ID"
  type        = string
}

variable "app_image_name" {
  description = "Docker image name"
  type        = string
}

variable "postgres_pwd" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}