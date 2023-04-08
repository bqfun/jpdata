data "google_project" "project" {}

resource "random_uuid" "default" {}

locals {
  name = "http-gcs-${random_uuid.default.result}"
}

resource "google_storage_bucket" "default" {
  name     = local.name
  location = var.loading.location
}

// loading

resource "google_storage_bucket_iam_member" "default" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

// extract and tweaks

resource "google_project_iam_member" "default" {
  project = data.google_project.project.project_id
  // workflow から run job を実行する
  role   = "roles/run.viewer"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_cloud_run_v2_job" "default" {
  name     = local.name
  location = var.loading.location

  template {
    template {
      containers {
        image = var.image

        env {
          name = "ETL"
          value = jsonencode([
            {
              Extraction      = var.extraction
              Transformations = var.tweaks
              Loading = {
                Bucket = google_storage_bucket.default.name
                Object = local.name
              }
            }
          ])
        }
      }
    }
  }
}

resource "google_cloud_run_v2_job_iam_member" "default" {
  location = google_cloud_run_v2_job.default.location
  name     = google_cloud_run_v2_job.default.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}
