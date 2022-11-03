resource "google_service_account" "httpbq" {
  account_id   = var.dataset_id
}

resource "google_project_iam_member" "httpbq" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/batch.jobsEditor",
    "roles/iam.serviceAccountUser",
  ])
  project  = var.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.httpbq.email}"
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
