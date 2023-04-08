data "google_project" "project" {}

resource "random_uuid" "default" {}

resource "google_storage_bucket_iam_member" "default" {
  bucket     = var.source_bucket_name
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "default" {
  dataset_id = var.destination_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}
