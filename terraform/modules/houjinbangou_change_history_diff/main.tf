resource "google_project_service" "project" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project = var.project_id
  service = each.key
  disable_on_destroy = false
}

resource "google_workflows_workflow" "httpgcs" {
  name            = "houjinbangou_change_history_diff"
  region          = var.region
  service_account = var.service_account_id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    bucket = var.bucket_name
    repositoryId = var.repository_repository_id
    location = var.repository_location
    secretName = "${var.secret_name}/versions/latest"
    workflowId = var.dataform_workflow_id
  })
}

resource "google_cloud_scheduler_job" "httpgcs" {
  name        = "houjinbangou_change_history_diff"
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

resource "google_cloudbuild_trigger" "dockerfiles_houjinbangou_change_history_diff" {
  name     = "dockerfiles-houjinbangou-change-history-diff"
  filename = "dockerfiles/houjinbangou_change_history_diff/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/houjinbangou_change_history_diff/**"]
}
