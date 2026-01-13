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

variable "default_availability_zone" {
  type        = string
  default 	  = "ru-central1-a"
}

variable "database_image_id" {
  type        = string
  description = "ID образа диска базы данных"
}


variable "app_replica_count" {
  description = "Количество реплик приложения"
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "Available zones for deployment"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}