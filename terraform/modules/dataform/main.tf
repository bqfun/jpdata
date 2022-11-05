resource "google_service_account" "dataform" {
  account_id   = "dataform"
}

resource "google_project_iam_member" "dataform" {
  for_each = toset(["roles/workflows.invoker", "roles/dataform.editor", "roles/logging.logWriter"])
  project  = var.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_workflows_workflow" "dataform" {
  name            = "dataform"
  region          = var.region
  service_account = google_service_account.dataform.id
  source_contents = templatefile("${path.module}/dataform.tftpl.yaml", {
    repository = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    connection_id = var.connection_id,
    bucket_source = var.bucket_source,
  })
}

resource "google_cloud_scheduler_job" "dataform_daily" {
  name        = "dataform-daily"
  schedule    = "0 0 * * *"
  time_zone   = "Asia/Tokyo"
  region      = var.region

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataform.id}/executions"
    http_method = "POST"
    body        = base64encode("{\"argument\": \"{\\\"includedTags\\\": [\\\"daily\\\"]}\"}")
    oauth_token {
      service_account_email = google_service_account.dataform.email
    }
  }
}

resource "google_cloud_scheduler_job" "dataform_monthly" {
  name        = "dataform-monthly"
  schedule    = "0 0 1 * *"
  time_zone   = "Asia/Tokyo"
  region      = var.region

  http_target {
    uri = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataform.id}/executions"
    http_method = "POST"
    body        = base64encode("{\"argument\": \"{\\\"includedTags\\\": [\\\"monthly\\\"]}\"}")
    oauth_token {
      service_account_email = google_service_account.dataform.email
    }
  }
}

resource "google_cloudbuild_trigger" "dataform" {
  name     = "dataform"
  filename = "cloudbuild.yaml"
  service_account = google_service_account.dataform.id

  github {
    owner = "bqfun"
    name  = "jpdata-dataform"
    push {
      branch = "^main$"
    }
  }
}
