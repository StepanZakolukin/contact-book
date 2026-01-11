variable "cloud_id" {
  type        = string
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  description = "ID директории в облаке"
}

variable "default_availability_zone" {
  type        = string
  description = "Зона доступности по умолчанию"
}

variable "ssh-key" {
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
