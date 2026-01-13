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

variable "database_image_id" {
  type        = string
  description = "ID образа диска базы данных"
}

variable "registry_id" {
  description = "Yandex Container Registry ID"
  type        = string
}

variable "app_image_name" {
  description = "Docker image name"
  type        = string
}

variable "default_availability_zone" {
  type        = string
  default 	  = "ru-central1-a"
}