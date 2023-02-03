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

resource "google_cloud_scheduler_job" "workflow" {
  name             = var.name
  schedule         = var.schedule
  time_zone        = var.time_zone
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.workflow.id}/executions"
    oauth_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}

resource "google_service_account" "service_account" {
  account_id = "wf-${substr(var.name, 0, 27)}"
}

resource "google_project_iam_member" "service_account" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_workflows_workflow" "workflow" {
  name            = var.name
  region          = var.region
  service_account = var.workflow_service_account_id
  source_contents = var.source_contents
}
