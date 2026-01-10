variable "folder_id" {
  type        = string
  description = "ID директории в облаке"
}

variable "db_subnet_id" {
  type        = string
  description = "ID подсети с базой данных"
}

variable "app_subnet_id" {
  type        = string
  description = "ID подсети с инстансами приложения"
}

variable "default_availability_zone" {
  type        = string
  description = "Зона доступности по умолчанию"
}

variable "postgres_pwd" {
  type        = string
  description = "Пароль от базы данных PostgreSQL"
}

variable "source_image_id" {
  type        = string
  description = "Образ загрузочного диска"
  default     = "fd8j5voj4pc21791fc8o"
}

variable "ssh_username" {
  type        = string
  description = "Имя пользователя от которого будут выполняться действия с ресурсом"
  default     = "admin"
}

variable "service_account_puller_id" {
  type = string
  description = "ID сервисного аккаунта с ролью container-registry.images.puller"
}

variable "registry_id" {
  type = string
  description = "Container Registry ID, в котором лежит docker-образ приложения"
}

variable "app_image_name" {
  type = string
  description = "Название docker-образа приложения"
}

variable "app_image_tag" {
  type = string
  description = "Тег docker-образа приложения"
}
