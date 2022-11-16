resource "google_project_service" "project" {
  for_each = toset([
    "analyticshub.googleapis.com",
    "artifactregistry.googleapis.com",
    "batch.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  project = var.google.project
  service = each.key
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "github_personal_access_token" {
  secret_id = "github-personal-access-token"

  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
resource "google_secret_manager_secret_iam_member" "github_personal_access_token" {
  project = google_secret_manager_secret.github_personal_access_token.project
  secret_id = google_secret_manager_secret.github_personal_access_token.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
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
  project = google_secret_manager_secret.houjinbangou_webapi_id.project
  secret_id = google_secret_manager_secret.houjinbangou_webapi_id.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${var.google.number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket" "source" {
  name     = "${var.google.project}-source"
  location = var.google.region
  uniform_bucket_level_access = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "source_eventarc" {
  name     = "${var.google.project}-source-eventarc"
  location = var.google.region
  uniform_bucket_level_access = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "httpgcs" {
  account_id   = "httpgcs"
}

resource "google_project_iam_member" "httpgcs" {
  for_each = toset([
    "roles/batch.jobsEditor",
    "roles/eventarc.eventReceiver",
    "roles/iam.serviceAccountUser",
    "roles/workflows.invoker",
  ])
  project  = var.google.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.httpgcs.email}"
}

module "gbizinfo" {
  source = "../../modules/httpgcs"
  project_id = var.google.project
  name = "gbizinfo"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 9 * * *"
  region = var.google.region
  source_contents = templatefile("templates/gbizinfo.tftpl.yaml", {
    bucket = google_storage_bucket.source_eventarc.name
  })
}

module "shukujitsu" {
  source = "../../modules/httpgcs"
  project_id = var.google.project
  name = "shukujitsu"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 6 * * *"
  region = var.google.region
  source_contents = templatefile("templates/shukujitsu.tftpl.yaml", {
    bucket = google_storage_bucket.source_eventarc.name
  })
}

module "houjinbangou" {
  source = "../../modules/httpgcs"
  project_id = var.google.project
  name = "houjinbangou"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 0 1 * *"
  region = var.google.region
  source_contents = templatefile("templates/houjinbangou_latest.tftpl.yaml", {
    bucket = google_storage_bucket.source_eventarc.name
    repositoryId = google_artifact_registry_repository.source.repository_id
    location = google_artifact_registry_repository.source.location
  })
}

module "houjinbangou_change_history_diff" {
  source = "../../modules/houjinbangou_change_history_diff"
  project_id = var.google.project
  name = "houjinbangou_change_history_diff"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 0 * * *"
  region = var.google.region

  bucket_name = google_storage_bucket.source.name
  repository_repository_id = google_artifact_registry_repository.source.repository_id
  repository_location = google_artifact_registry_repository.source.location
  secret_name = google_secret_manager_secret.houjinbangou_webapi_id.name
  dataform_workflow_id = module.dataform.workflow_id
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
  project_id = var.google.project
  project_number = var.google.number
  region = var.google.region
  bucket_name = google_storage_bucket.source.name
  bucket_eventarc_name = google_storage_bucket.source_eventarc.name
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
  lifecycle {
    prevent_destroy = true
  }
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