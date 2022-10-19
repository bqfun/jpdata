resource "google_service_account" "httpbq" {
  account_id   = var.dataset_id
}

resource "google_project_iam_member" "httpbq" {
  for_each = toset(["roles/workflows.invoker", "roles/cloudfunctions.invoker"])
  project  = var.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.httpbq.email}"
}

resource "google_storage_bucket" "httpbq" {
  name     = "${var.project}-${var.dataset_id}"
  location = "asia-northeast1"
}

resource "google_workflows_workflow" "httpbq" {
  name            = var.dataset_id
  region          = "asia-northeast1"
  service_account = google_service_account.httpbq.id
  source_contents = var.source_contents
}

resource "google_cloud_scheduler_job" "httpbq" {
  name        = var.dataset_id
  schedule    = var.schedule
  time_zone   = "Asia/Tokyo"
  region      = "asia-northeast1"

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.httpbq.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.httpbq.email
    }
  }
}

resource "google_bigquery_dataset" "httpbq" {
  dataset_id                      = var.dataset_id
  description                     = var.description
  default_table_expiration_ms     = 5184000000
  default_partition_expiration_ms = 5184000000
  location                        = "asia-northeast1"
}

resource "google_bigquery_dataset" "httpbq-staging" {
  dataset_id                      = "${var.dataset_id}_staging"
  description                     = var.description
  default_table_expiration_ms     = 5184000000
  default_partition_expiration_ms = 5184000000
  location                        = "asia-northeast1"
}

resource "google_secret_manager_secret_iam_member" "member" {
  project   = var.project
  secret_id = var.slack_webhook_url_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.httpbq.email}"
}

