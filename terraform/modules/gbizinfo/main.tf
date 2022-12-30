resource "google_project_service" "workflow" {
  for_each = toset([
    "cloudscheduler.googleapis.com",
    "iam.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_workflows_workflow" "workflow" {
  name            = "gbizinfo"
  region          = var.region
  service_account = var.workflow_service_account_id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    bucket = var.bucket_eventarc_name
  })
}

resource "google_cloud_scheduler_job" "workflow" {
  name      = "gbizinfo"
  schedule  = var.schedule
  time_zone = "Asia/Tokyo"
  region    = var.region

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.workflow.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.workflow_invoker.email
    }
  }
}

resource "google_service_account" "workflow_invoker" {
  account_id = "gbizinfo-invoker"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}
