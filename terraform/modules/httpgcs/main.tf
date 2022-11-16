resource "google_project_service" "project" {
  for_each = toset([
    "cloudscheduler.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project = var.project_id
  service = each.key
  disable_on_destroy = false
}

resource "google_workflows_workflow" "httpgcs" {
  name            = var.name
  region          = var.region
  service_account = var.service_account_id
  source_contents = var.source_contents
}

resource "google_cloud_scheduler_job" "httpgcs" {
  name        = var.name
  schedule    = var.schedule
  time_zone   = "Asia/Tokyo"
  region      = var.region

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.httpgcs.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}
