resource "google_project_service" "project" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project            = var.google.project
  service            = each.key
  disable_on_destroy = false
}

resource "google_storage_bucket" "source" {
  name                        = "${var.google.project}-source"
  location                    = var.google.region
  uniform_bucket_level_access = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "source_eventarc" {
  name                        = "${var.google.project}-source-eventarc"
  location                    = var.google.region
  uniform_bucket_level_access = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "daily" {
  account_id = "daily-invoker"
}

resource "google_project_iam_member" "daily" {
  project = var.google.project
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.daily.email}"
}

module "daily" {
  source                      = "../../modules/scheduled_workflow"
  name                        = "daily"
  project_id                  = var.google.project
  region                      = var.google.region
  schedule                    = "0 9 * * *"
  time_zone                   = "Asia/Tokyo"
  workflow_service_account_id = google_service_account.daily.id
  source_contents             = <<-EOF
  - etlJobs:
      parallel:
        for:
          value: parent
          in:
            - ${module.shukujitsu.workflow_id}
            - ${module.base_registry_address.workflow_id}
            - ${module.gbizinfo.workflow_id}
          steps:
            - etl:
                call: googleapis.workflowexecutions.v1.projects.locations.workflows.executions.create
                args:
                  parent: $${parent}
  - checkIfFirstDayOfMonth:
      switch:
        - condition: $${text.substring(time.format(sys.now()), 8, 10) == "01"}
          steps:
            - stepA:
                assign:
                  - argument:
                      transitiveDependentsIncluded: false
                      includedTags: ["daily", "monthly"]
        - condition: true
          steps:
            - stepB:
                assign:
                  - argument:
                      transitiveDependentsIncluded: false
                      includedTags: ["daily"]
  - wait:
      call: sys.sleep
      args:
        seconds: 120
  - dataform:
      call: googleapis.workflowexecutions.v1.projects.locations.workflows.executions.create
      args:
        parent: ${module.dataform.workflow_id}
        body:
          argument: $${json.encode_to_string(argument)}
EOF
}

module "houjinbangou_latest" {
  source                   = "../../modules/houjinbangou_latest"
  project_id               = var.google.project
  schedule                 = "0 0 1 * *"
  region                   = var.google.region
  bucket_eventarc_name     = google_storage_bucket.source_eventarc.name
  repository_repository_id = google_artifact_registry_repository.source.repository_id
  repository_location      = google_artifact_registry_repository.source.location
}

module "houjinbangou_change_history_diff" {
  source         = "../../modules/houjinbangou_change_history_diff"
  project_id     = var.google.project
  project_number = var.google.number
  schedule       = "0 0 * * *"
  region         = var.google.region

  bucket_name              = google_storage_bucket.source.name
  repository_repository_id = google_artifact_registry_repository.source.repository_id
  repository_location      = google_artifact_registry_repository.source.location
  dataform_workflow_id     = module.dataform.workflow_id
}

module "dataform" {
  source               = "../../modules/dataform"
  project_id           = var.google.project
  project_number       = var.google.number
  region               = var.google.region
  bucket_name          = google_storage_bucket.source.name
  bucket_eventarc_name = google_storage_bucket.source_eventarc.name
}

resource "google_artifact_registry_repository" "source" {
  location      = var.google.region
  repository_id = "source"
  format        = "DOCKER"
  lifecycle {
    prevent_destroy = true
  }
}

module "analyticshub" {
  source = "../../modules/analyticshub"
}

module "gbizinfo" {
  source = "../../modules/gbizinfo"
}

module "shukujitsu" {
  source = "../../modules/shukujitsu"
}

module "base_registry_address" {
  source = "../../modules/base_registry_address"
}

resource "google_project_iam_member" "health_dashboard" {
  project = var.google.project
  role    = "roles/bigquery.metadataViewer"
  member  = "user:na0@bqfun.jp"
}
