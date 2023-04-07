data "google_project" "project" {}

resource "random_string" "default" {
  length  = 6
  lower   = true
  upper   = false
  special = false
  numeric = false
}

locals {
  name = "etlt-${random_string.default.result}"
}

resource "google_storage_bucket" "default" {
  name          = local.name
  location      = var.loading.location
}

resource "google_service_account" "default" {
  account_id = local.name
}

// transformation

resource "google_bigquery_dataset" "dataset" {
  location   = var.transformation.bigquery_dataset_location
  dataset_id = var.transformation.bigquery_dataset_id
}

resource "google_bigquery_dataset_iam_member" "t" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.default.email}"
}

resource "google_workflows_workflow" "transformation" {
  name            = "etlt-t-${random_string.default.result}"
  region          = var.loading.location
  service_account = google_service_account.default.id

  source_contents = <<-EOT
  - transform:
      call: googleapis.bigquery.v2.jobs.insert
      args:
        projectId: ${google_bigquery_dataset.dataset.project}
        body:
          configuration:
            query:
              defaultDataset:
                datasetId: ${google_bigquery_dataset.dataset.dataset_id}
                projectId: ${google_bigquery_dataset.dataset.project}
              query: |-
                ${indent(14, var.transformation.query)}
              tableDefinitions:
                file:
                  sourceUris:
                    - gs://${google_storage_bucket.default.name}/${local.name}
                  schema:
                    fields:
                      %{ for item in var.transformation.fields ~}

                      - name: ${item}
                        type: STRING
                      %{ endfor }
                  sourceFormat: CSV
                  csvOptions:
                    skipLeadingRows: 1
              useLegacySql: false
  EOT
}

resource "google_eventarc_trigger" "eventarc" {
  name     = "eventarc"
  location = var.loading.location
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.default.name
  }
  destination {
    workflow = google_workflows_workflow.transformation.id
  }
  service_account = google_service_account.default.email
  depends_on = [
    google_project_iam_member.eventarc_gs,
    google_project_iam_member.eventarc_pubsub,
  ]
}

// このトリガーでは、Cloud Storage 経由でイベントを受け取るために、
// サービス アカウント service-120299025068@gs-project-accounts.iam.gserviceaccount.com に
// ロール roles/pubsub.publisher が付与されている必要があります。
resource "google_project_iam_member" "eventarc_gs" {
  project = data.google_project.project.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

// Cloud Pub/Sub で ID トークンを作成するには、
// このプロジェクトのサービス アカウント service-120299025068@gcp-sa-pubsub.iam.gserviceaccount.com に
// ロール roles/iam.serviceAccountTokenCreator が付与されている必要があります。
resource "google_project_iam_member" "eventarc_pubsub" {
  project = data.google_project.project.name
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

// loading

resource "google_storage_bucket_iam_member" "default" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.default.email}"
}

// extract and tweaks

resource "google_cloud_run_v2_job" "default" {
  name     = local.name
  location = var.loading.location

  template {
    template{
      containers {
        image = var.image

        env {
          name = "ETL"
          value = jsonencode([
            {
              Extraction = var.extraction
              Transformations = var.tweaks
              Loading = {
                Bucket = google_storage_bucket.default.name
                Object = local.name
              }
            }
          ])
        }
      }
    }
  }
}

resource "google_cloud_run_v2_job_iam_member" "default" {
  name   = google_cloud_run_v2_job.default.name
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.default.email}"
}

resource "google_workflows_workflow" "etl" {
  name            = "etlt-etl-${random_string.default.result}"
  region          = var.loading.location
  service_account = google_service_account.default.id

  source_contents = <<-EOT
  - etl:
      call: googleapis.run.v1.namespaces.jobs.run
      args:
          name: namespaces/${data.google_project.project.name}/jobs/${google_cloud_run_v2_job.default.name}
          location: ${google_cloud_run_v2_job.default.location}
  EOT
}
