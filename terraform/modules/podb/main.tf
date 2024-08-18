resource "google_storage_bucket" "main" {
  name     = "podb"
  location = "us-central1"
}

resource "google_storage_bucket_iam_member" "main" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${var.cloud_storage_service_account}"
}