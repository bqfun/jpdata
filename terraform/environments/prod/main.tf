resource "google_project_service" "project" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "datalineage.googleapis.com",
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

resource "google_project_iam_member" "simplte" {
  project = var.google.project
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${module.simplte.invoker_email}"
}

module "daily" {
  source                      = "../../modules/scheduled_workflow"
  name                        = "daily"
  project_id                  = var.google.project
  region                      = var.google.region
  schedule                    = "0 9 * * *"
  time_zone                   = "Asia/Tokyo"
  workflow_service_account_id = module.simplte.invoker_id
  source_contents             = <<-EOF
  - init:
      assign:
        - bodies:
          - extraction:
              method: GET
              url: https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv
            transformations:
              - call: fromShiftJIS
            loading:
              bucket: ${google_storage_bucket.source_eventarc.name}
              object: syukujitsu.csv
  - gbizinfo:
      for:
        value: value
        in:
          - object: basic
            downfile: "7"
          - object: certification
            downfile: "8"
          - object: commendation
            downfile: "9"
          - object: subsidy
            downfile: "10"
          - object: procurement
            downfile: "11"
          - object: patent
            downfile: "12"
          - object: finance
            downfile: "13"
          - object: workplace
            downfile: "14"
        steps:
          - gbizinfoAssign:
              assign:
                - body:
                    extraction:
                      method: POST
                      url: https://info.gbiz.go.jp/hojin/Download
                      body:
                        downenc: UTF-8
                        downfile: $${value.downfile}
                        downtype: csv
                    loading:
                      bucket: ${google_storage_bucket.source_eventarc.name}
                      object: $${"gbizinfo/" + value.object + ".csv"}
                - bodies: $${list.concat(bodies, body)}
  - baseRegistryAddress:
      for:
        value: value
        in:
          - mt_town
          - mt_city
          - mt_pref
        steps:
          - baseRegistryAddressAssign:
              assign:
                - body:
                    extraction:
                      method: GET
                      url: $${"https://gov-csv-export-public.s3.ap-northeast-1.amazonaws.com/" + value + "/" + value + "_all.csv.zip"}
                    transformations:
                      - call: unzip
                    loading:
                      bucket: ${google_storage_bucket.source_eventarc.name}
                      object: $${"base_registry_address/" + value + "_all.csv"}
                      name: $${value + "_all.csv"}
                - bodies: $${list.concat(bodies, body)}
  - download:
      parallel:
        for:
          value: body
          in: $${bodies}
          steps:
            - simplte:
                call: http.post
                args:
                  url: ${module.simplte.url}
                  auth:
                    type: OIDC
                  body: $${body}
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

resource "google_artifact_registry_repository" "jpdata" {
  location      = var.google.region
  repository_id = "jpdata"
  format        = "DOCKER"
  lifecycle {
    prevent_destroy = true
  }
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
  repository_location   = google_artifact_registry_repository.jpdata.location
  repository_project_id = google_artifact_registry_repository.jpdata.project
  repository_id         = google_artifact_registry_repository.jpdata.repository_id
}

resource "google_artifact_registry_repository" "etl" {
  location      = "us-west1"
  repository_id = "jpdata-us-west1"
  format        = "DOCKER"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_cloudbuild_trigger" "etl" {
  name     = "dockerfiles-etl"
  filename = "dockerfiles/etl/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/etl/**"]
}

module "shukujitsu" {
  source     = "../../modules/etlt"
  image      = "us-west1-docker.pkg.dev/jpdata/${google_artifact_registry_repository.etl.repository_id}/etl"
  extraction = {
    url = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
  }
  tweaks = [
    {
      call = "convert"
      args = {
        charset = "shift-jis"
      }
    }
  ]
  loading = {
    location = "us-west1"
  }
  transformation = {
    bigquery_dataset_id       = "shukujitsu__us"
    bigquery_dataset_location = "US"
    fields                    = ["date", "name"]
    query = <<-EOF
    CREATE OR REPLACE TABLE holidays(
      date DATE PRIMARY KEY NOT ENFORCED NOT NULL OPTIONS(description="国民の祝日・休日月日"),
      name STRING NOT NULL OPTIONS(description="国民の祝日・休日名称"),
    )
    OPTIONS(
      description="https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv",
      friendly_name="国民の祝日",
      labels=[
        ("freshness", "daily")
      ]
    )
    AS
    SELECT
      PARSE_DATE("%Y/%m/%d", date) AS date,
      name,
    FROM
      file
    QUALIFY
      IF(1013<=COUNT(*)OVER(), TRUE, ERROR("COUNT(*) < 1013"))
      AND IF(1=COUNT(*)OVER(PARTITION BY date), TRUE, ERROR("A duplicate date has been found"))
    ORDER BY
      date
    EOF
  }
}

resource "google_project_iam_member" "health_dashboard" {
  project = var.google.project
  role    = "roles/bigquery.metadataViewer"
  member  = "user:na0@bqfun.jp"
}
