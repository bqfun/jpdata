resource "google_project_service" "project" {
  for_each = toset([
    "batch.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_workflows_workflow" "httpgcs" {
  name            = "houjinbangou_change_history_diff"
  region          = var.region
  service_account = google_service_account.workflow.id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    bucket       = var.bucket_name
    repositoryId = var.repository_repository_id
    location     = var.repository_location
    secretName   = "${google_secret_manager_secret.houjinbangou_webapi_id.name}/versions/latest"
    workflowId   = var.dataform_workflow_id
  })
}

resource "google_cloud_scheduler_job" "httpgcs" {
  name      = "houjinbangou_change_history_diff"
  schedule  = var.schedule
  time_zone = "Asia/Tokyo"
  region    = var.region

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.httpgcs.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.workflow_invoker.email
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

resource "google_secret_manager_secret" "houjinbangou_webapi_id" {
  secret_id = "houjinbangou-webapi-id"

  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
resource "google_secret_manager_secret_iam_member" "houjinbangou_webapi_id" {
  project   = google_secret_manager_secret.houjinbangou_webapi_id.project
  secret_id = google_secret_manager_secret.houjinbangou_webapi_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_service_account" "workflow" {
  account_id = "houjinbangou-diff-workflow"
}

resource "google_project_iam_member" "workflow" {
  project = var.project_id
  role    = "roles/batch.jobsEditor"
  member  = "serviceAccount:${google_service_account.workflow.email}"
}

data "google_compute_default_service_account" "default" {
}
resource "google_service_account_iam_member" "workflow" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.workflow.email}"
}

resource "google_service_account" "workflow_invoker" {
  account_id = "houjinbangou-change-history-diff-workflow-invoker"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}
