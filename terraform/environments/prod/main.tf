resource "google_storage_bucket" "source" {
  name     = "${var.google.project}-source"
  location = var.google.region
  uniform_bucket_level_access = true
}

resource "google_service_account" "httpgcs" {
  account_id   = "httpgcs"
}

resource "google_project_iam_member" "httpgcs" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/batch.jobsEditor",
    "roles/iam.serviceAccountUser",
  ])
  project  = var.google.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.httpgcs.email}"
}

module "gbizinfo" {
  source = "../../modules/httpgcs"
  name = "gbizinfo"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 9 * * *"
  region = var.google.region
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
    objectPrefix = "gbizinfo/"
    workflowId = module.dataform.workflow_id
  })
}

module "shukujitsu" {
  source = "../../modules/httpgcs"
  name = "shukujitsu"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 6 * * *"
  region = var.google.region
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
    object = "syukujitsu.csv"
    workflowId = module.dataform.workflow_id
  })
}

module "houjinbangou" {
  source = "../../modules/httpgcs"
  name = "houjinbangou"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 0 1 * *"
  region = var.google.region
  source_contents = templatefile("source_contents/houjinbangou.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
    object = "houjinbangou.csv"
    repositoryId = google_artifact_registry_repository.source.repository_id
    location = google_artifact_registry_repository.source.location
    workflowId = module.dataform.workflow_id
  })
}

resource "google_project_iam_member" "dataform" {
  for_each = toset([
    "roles/dataform.serviceAgent",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataOwner",
    "roles/bigquery.connectionAdmin",
  ])
  project = var.google.project
  role    = each.key
  member  = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

module "dataform" {
  source = "../../modules/dataform"
  project = var.google.project
  region = var.google.region
  connection_id = "${google_bigquery_connection.main.project}.${google_bigquery_connection.main.location}.${google_bigquery_connection.main.connection_id}"
  bucket_source = google_storage_bucket.source.name
}

resource "google_bigquery_connection" "main" {
  connection_id = "main"
  project = var.google.project
  location = var.google.region
  cloud_resource {}
}

resource "google_project_iam_member" "mainConnectionPermissionGrant" {
  project = var.google.project
  role = "roles/storage.objectViewer"
  member = format("serviceAccount:%s", google_bigquery_connection.main.cloud_resource[0].service_account_id)
}

resource "google_project_iam_member" "cloud_batch_upload_objects_to_cloud_storage" {
  project = var.google.project
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.google.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "source" {
  location      = var.google.region
  repository_id = "source"
  format        = "DOCKER"
}

resource "google_cloudbuild_trigger" "dockerfiles_houjinbangou_latest" {
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
