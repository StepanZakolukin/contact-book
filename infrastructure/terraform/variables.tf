variable "cloud_id" {
  type        = string
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  description = "ID каталога"
}

variable "bucket_name" {
  type        = string
  description = "Имя Object Storage bucket (должно быть глобально уникальным)"
}

variable "service_account_name" {
  type        = string
  default     = "object-storage-sa"
}

variable "storage_class" {
  type        = string
  default     = "STANDARD"
}