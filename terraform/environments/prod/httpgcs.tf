resource "google_storage_bucket" "httpgcs" {
  name     = "${var.project}-httpgcs"
  location = "asia-northeast1"
}

data "archive_file" "httpgcs" {
  type        = "zip"
  source_dir  = "httpgcs"
  output_path = "httpgcs.zip"
}

resource "google_storage_bucket_object" "httpgcs" {
  name   = "httpgcs-${data.archive_file.httpgcs.output_md5}.zip"
  bucket = google_storage_bucket.httpgcs.name
  source = data.archive_file.httpgcs.output_path
}

resource "google_service_account" "httpgcs" {
  account_id   = "httpgcs"
}

resource "google_project_iam_member" "httpgcs" {
  project  = var.project
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${google_service_account.httpgcs.email}"
}

resource "google_cloudfunctions_function" "httpgcs" {
  name        = "httpgcs"
  runtime     = "go116"
  region      = "asia-northeast1"

  available_memory_mb          = 256
  source_archive_bucket        = google_storage_bucket_object.httpgcs.bucket
  source_archive_object        = google_storage_bucket_object.httpgcs.name
  trigger_http                 = true
  https_trigger_security_level = "SECURE_ALWAYS"
  timeout                      = 540
  entry_point                  = "Handler"
  service_account_email        = google_service_account.httpgcs.email
}
