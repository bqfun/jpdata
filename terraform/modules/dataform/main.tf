resource "google_project_service" "project" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "dataform.googleapis.com",
    "iam.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "dataform" {
  account_id = "dataform"
}

resource "google_project_iam_member" "dataform" {
  for_each = toset(["roles/dataform.editor", "roles/logging.logWriter"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_workflows_workflow" "dataform" {
  name            = "dataform"
  region          = var.region
  service_account = google_service_account.dataform_workflow_invoker.id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    repository      = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    connection_id   = "${google_bigquery_connection.main.project}.${google_bigquery_connection.main.location}.${google_bigquery_connection.main.connection_id}",
    bucket          = var.bucket_name,
    bucket_eventarc = var.bucket_eventarc_name,
  })
}

resource "google_cloud_scheduler_job" "dataform_daily" {
  name      = "dataform-daily"
  schedule  = "0 0 * * *"
  time_zone = "Asia/Tokyo"
  region    = var.region

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataform.id}/executions"
    http_method = "POST"
    body        = base64encode("{\"argument\": \"{\\\"includedTags\\\": [\\\"daily\\\"]}\"}")
    oauth_token {
      service_account_email = google_service_account.dataform.email
    }
  }
}

resource "google_cloud_scheduler_job" "dataform_monthly" {
  name      = "dataform-monthly"
  schedule  = "0 0 1 * *"
  time_zone = "Asia/Tokyo"
  region    = var.region

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataform.id}/executions"
    http_method = "POST"
    body        = base64encode("{\"argument\": \"{\\\"includedTags\\\": [\\\"monthly\\\"]}\"}")
    oauth_token {
      service_account_email = google_service_account.dataform.email
    }
  }
}

resource "google_cloudbuild_trigger" "dataform" {
  name            = "dataform"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.dataform.id

  github {
    owner = "bqfun"
    name  = "jpdata-dataform"
    push {
      branch = "^main$"
    }
  }
}

resource "google_service_account" "dataform_workflow_invoker" {
  account_id = "dataform-workflow-invoker"
}

resource "google_project_iam_member" "eventarc" {
  for_each = toset([
    "roles/eventarc.eventReceiver",
    "roles/workflows.invoker",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dataform_workflow_invoker.email}"
}

resource "google_eventarc_trigger" "eventarc" {
  name     = "eventarc"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_eventarc_name
  }
  destination {
    workflow = google_workflows_workflow.dataform.id
  }
  service_account = google_service_account.dataform_workflow_invoker.email
  depends_on = [
    google_project_iam_member.eventarc,
    google_project_iam_member.eventarc_gs,
    google_project_iam_member.eventarc_pubsub,
  ]
}

// このトリガーでは、Cloud Storage 経由でイベントを受け取るために、
// サービス アカウント service-120299025068@gs-project-accounts.iam.gserviceaccount.com に
// ロール roles/pubsub.publisher が付与されている必要があります。
resource "google_project_iam_member" "eventarc_gs" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

// Cloud Pub/Sub で ID トークンを作成するには、
// このプロジェクトのサービス アカウント service-120299025068@gcp-sa-pubsub.iam.gserviceaccount.com に
// ロール roles/iam.serviceAccountTokenCreator が付与されている必要があります。
resource "google_project_iam_member" "eventarc_pubsub" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_bigquery_connection" "main" {
  connection_id = "main"
  project       = var.project_id
  location      = var.region
  cloud_resource {}
}

resource "google_project_iam_member" "main_connection_permission_grant" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = format("serviceAccount:%s", google_bigquery_connection.main.cloud_resource[0].service_account_id)
}