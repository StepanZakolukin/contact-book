resource "yandex_iam_service_account" "sa" {
  name        = var.service_account_name
  description = "Service account for Object Storage access"
}

resource "yandex_iam_service_account_static_access_key" "sa_keys" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_role" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_storage_bucket" "bucket" {
  bucket = var.bucket_name
  folder_id = var.folder_id
  default_storage_class = var.storage_class
}