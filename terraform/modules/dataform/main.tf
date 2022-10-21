resource "google_service_account" "dataform" {
  account_id   = "dataform"
}

resource "google_project_iam_member" "dataform" {
  for_each = toset(["roles/workflows.invoker", "roles/dataform.editor"])
  project  = var.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_workflows_workflow" "dataform" {
  name            = "dataform"
  region          = "asia-northeast1"
  service_account = google_service_account.dataform.id
  source_contents = templatefile("${path.module}/dataform.tftpl.yaml", {
    repository = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    connection_id = var.connection_id,
    bucket_gbizinfo = var.bucket_gbizinfo,
    bucket_shukujitsu = var.bucket_shukujitsu,
  })
}

resource "google_cloud_scheduler_job" "dataform" {
  name        = "dataform-daily"
  schedule    = "0 0 * * *"
  time_zone   = "Asia/Tokyo"
  region      = "asia-northeast1"

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataform.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.dataform.email
    }
  }
}
