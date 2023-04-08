resource "google_project_service" "workflow" {
  for_each = toset([
    "batch.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_workflows_workflow" "workflow" {
  name            = "houjinbangou_latest"
  region          = var.region
  service_account = google_service_account.workflow.id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    bucket       = var.bucket_eventarc_name
    repositoryId = var.repository_repository_id
    location     = var.repository_location
  })
}

resource "google_cloud_scheduler_job" "workflow" {
  name      = "houjinbangou_latest"
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

resource "google_cloudbuild_trigger" "workflow" {
  name     = "dockerfiles-houjinbangou-latest"
  filename = "dockerfiles/houjinbangou_latest/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/houjinbangou_latest/**"]
}

resource "google_service_account" "workflow" {
  account_id = "houjinbangou-latest"
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
  account_id = "houjinbangou-latest-invoker"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_invoker.email}"
}

resource "google_storage_bucket_iam_member" "cloud_batch" {
  bucket = var.bucket_eventarc_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}
