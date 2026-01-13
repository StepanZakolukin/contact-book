variable "folder_id" {
  type        = string
  description = "ID директории в облаке"
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
  description = "ID образа загрузочного диска, c предустановленным Docker"
  default     = "fd8j5voj4pc21791fc8o"
}

variable "ssh_username" {
  type        = string
  description = "Имя пользователя от которого будут выполняться действия с ресурсом"
  default     = "yc-user"
}

variable "service_account_puller_id" {
  type        = string
  description = "ID сервисного аккаунта с ролью container-registry.images.puller"
}

variable "registry_id" {
  type        = string
  description = "Container Registry ID, в котором лежит docker-образ приложения"
}

variable "app_image_name" {
  type        = string
  description = "Название docker-образа приложения"
  default     = "contact-book"
}

variable "app_image_tag" {
  type        = string
  description = "Тег docker-образа приложения"
  default     = "latest"
}

variable "default_subnet_id" {
  type        = string
  description = "ID подсети по умолчанию"
}

variable "ssh_key" {
  type        = string
  description = "SSH ключ пользователя"
}
