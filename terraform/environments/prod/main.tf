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

module "gbizinfo" {
  source                = "../../modules/gbizinfo"
  project_id            = var.google.project
  schedule              = "0 9 * * *"
  region                = var.google.region
  bucket_eventarc_name  = google_storage_bucket.source_eventarc.name
}

resource "google_cloud_scheduler_job" "shukujitsu" {
  name       = "shukujitsu"
  schedule   = "0 6 * * *"
  time_zone  = "Asia/Tokyo"
  project_id = var.google.project
  region     = var.google.region

  http_target {
    uri         = module.simplte.url
    http_method = "POST"
    body = base64encode(<<-EOT
      {
        "extraction": {
          "method": "GET",
          "url": "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
        },
        "transformations": [
          {
            "call": "fromShiftJIS"
          }
        ],
        "loading": {
          "bucket": "${google_storage_bucket.source_eventarc.name}",
          "object": "syukujitsu.csv"
        }
      }
      EOT
    )
    oidc_token {
      service_account_email = module.simplte.invoker_email
    }
  }
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
  source                = "../../modules/houjinbangou_change_history_diff"
  project_id            = var.google.project
  project_number        = var.google.number
  schedule              = "0 0 * * *"
  region                = var.google.region

  bucket_name              = google_storage_bucket.source.name
  repository_repository_id = google_artifact_registry_repository.source.repository_id
  repository_location      = google_artifact_registry_repository.source.location
  dataform_workflow_id     = module.dataform.workflow_id
}

resource "google_cloud_scheduler_job" "base_registry_address" {
  name       = "base_registry_address"
  schedule   = "0 0 1 * *"
  time_zone  = "Asia/Tokyo"
  project_id = var.google.project
  region     = var.google.region

  http_target {
    uri         = module.simplte.url
    http_method = "POST"
    body = base64encode(<<-EOT
      {
        "extraction": {
          "method": "GET",
          "url": "https://gov-csv-export-public.s3.ap-northeast-1.amazonaws.com/mt_town/mt_town_all.csv.zip"
        },
        "transformations": [
          {
            "call": "unzip"
          }
        ],
        "loading": {
          "bucket": "${google_storage_bucket.source_eventarc.name}",
          "object": "base_registry_address/mt_town_all.csv",
          "name": "mt_town_all.csv"
        }
      }
      EOT
    )
    oidc_token {
      service_account_email = module.simplte.invoker_email
    }
  }
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

module "lineage" {
  source     = "../../modules/lineage"
  project_id = var.google.project
  location   = var.google.region
}

module "analyticshub" {
  source = "../../modules/analyticshub"
  project_number = var.google.number
  location       = var.google.region
}

module "simplte" {
  source                = "../../modules/simplte"
  project_id            = var.google.project
  location              = var.google.region
  repository_location   = google_artifact_registry_repository.source.location
  repository_project_id = google_artifact_registry_repository.source.project
  repository_id         = google_artifact_registry_repository.source.repository_id
}
