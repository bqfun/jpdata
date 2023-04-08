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
        - bodies: []
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
  - etlJobs:
      parallel:
        for:
          value: parent
          in:
            - ${module.shukujitsu.workflow_id}
            - ${module.base_registry_address_town.workflow_id}
          steps:
            - etl:
                call: googleapis.workflowexecutions.v1.projects.locations.workflows.executions.create
                args:
                  parent: $${parent}
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

resource "google_artifact_registry_repository" "jpdata" {
  location      = var.google.region
  repository_id = "jpdata"
  format        = "DOCKER"
  lifecycle {
    prevent_destroy = true
  }
}

module "analyticshub" {
  source         = "../../modules/analyticshub"
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
  source = "../../modules/workflows_http_to_bigquery_datasets"
  image  = "us-west1-docker.pkg.dev/jpdata/${google_artifact_registry_repository.etl.repository_id}/etl:latest"
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
  transformation = {
    dataset_id_suffix = "shukujitsu"
    fields            = ["date", "name"]
    query             = <<-EOF
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

module "base_registry_address_town" {
  source = "../../modules/workflows_http_to_bigquery_datasets"
  image  = "us-west1-docker.pkg.dev/jpdata/${google_artifact_registry_repository.etl.repository_id}/etl:latest"
  extraction = {
    url = "https://catalog.registries.digital.go.jp/rsc/address/mt_town_all.csv.zip"
  }
  tweaks = [
    {
      call = "unzip"
    }
  ]
  transformation = {
    dataset_id_suffix = "base_registry_address"
    fields = [
      "local_goverment_code",
      "town_id",
      "town_classification_code",
      "prefecture",
      "prefecture_kana",
      "prefecture_en",
      "district",
      "district_kana",
      "district_en",
      "city",
      "city_kana",
      "city_en",
      "government_ordinance_city",
      "government_ordinance_city_kana",
      "government_ordinance_city_en",
      "ooaza",
      "ooaza_kana",
      "ooaza_en",
      "chome",
      "chome_kana",
      "chome_number",
      "koaza",
      "koaza_kana",
      "koaza_en",
      "is_residential",
      "_01",
      "_02",
      "_03",
      "_04",
      "_05",
      "_06",
      "_07",
      "effective_from",
      "effective_to",
      "original_data_code",
      "postal_code",
      "remarks",
    ]
    query = <<-EOF
    CREATE OR REPLACE TABLE town(
      PRIMARY KEY (local_goverment_code, town_id, is_residential) NOT ENFORCED,
      local_goverment_code STRING NOT NULL OPTIONS(description="全国地方公共団体コード"),
      town_id STRING NOT NULL OPTIONS(description="町字id"),
      town_classification_code STRING NOT NULL OPTIONS(description="町字区分コード"),
      prefecture STRING NOT NULL OPTIONS(description="都道府県名"),
      prefecture_kana STRING NOT NULL OPTIONS(description="都道府県名_カナ"),
      prefecture_en STRING NOT NULL OPTIONS(description="都道府県名_英字"),
      district STRING OPTIONS(description="郡名"),
      district_kana STRING OPTIONS(description="郡名_カナ"),
      district_en STRING OPTIONS(description="郡名_英字"),
      city STRING NOT NULL OPTIONS(description="市区町村名"),
      city_kana STRING NOT NULL OPTIONS(description="市区町村名_カナ"),
      city_en STRING NOT NULL OPTIONS(description="市区町村名_英字"),
      government_ordinance_city STRING OPTIONS(description="政令市区名"),
      government_ordinance_city_kana STRING OPTIONS(description="政令市区名_カナ"),
      government_ordinance_city_en STRING OPTIONS(description="政令市区名_英字"),
      ooaza STRING OPTIONS(description="大字・町名"),
      ooaza_kana STRING OPTIONS(description="大字・町名_カナ"),
      ooaza_en STRING OPTIONS(description="大字・町名_英字"),
      chome STRING OPTIONS(description="丁目名"),
      chome_kana STRING OPTIONS(description="丁目名_カナ"),
      chome_number INTEGER OPTIONS(description="丁目名_数字"),
      koaza STRING OPTIONS(description="小字名"),
      koaza_kana STRING OPTIONS(description="小字名_カナ"),
      koaza_en STRING OPTIONS(description="小字名_英字"),
      is_residential BOOL OPTIONS(description="住居表示フラグ"),
      _01 STRING OPTIONS(description="住居表示方式コード"),
      _02 STRING OPTIONS(description="大字・町_通称フラグ"),
      _03 STRING OPTIONS(description="小字_通称フラグ"),
      _04 STRING OPTIONS(description="大字・町外字フラグ"),
      _05 STRING OPTIONS(description="小字外字フラグ"),
      _06 STRING OPTIONS(description="状態フラグ"),
      _07 STRING OPTIONS(description="起番フラグ"),
      effective_from DATE NOT NULL OPTIONS(description="効力発生日"),
      effective_to DATE OPTIONS(description="廃止日"),
      original_data_code STRING NOT NULL OPTIONS(description="原典資料コード"),
      postal_code STRING OPTIONS(description="郵便番号"),
      remarks STRING OPTIONS(description="備考"),
    )
    OPTIONS(
      description="https://catalog.registries.digital.go.jp/rsc/address/mt_town_all.csv.zip",
      friendly_name="日本 町字マスター データセット",
      labels=[
        ("freshness", "daily")
      ]
    )
    AS
    SELECT
      local_goverment_code,
      town_id,
      town_classification_code,
      prefecture,
      prefecture_kana,
      prefecture_en,
      district,
      district_kana,
      district_en,
      city,
      city_kana,
      city_en,
      government_ordinance_city,
      government_ordinance_city_kana,
      government_ordinance_city_en,
      ooaza,
      ooaza_kana,
      ooaza_en,
      chome,
      chome_kana,
      CAST(chome_number AS INT64) AS chome_number,
      koaza,
      koaza_kana,
      koaza_en,
      CASE is_residential
        WHEN "1" THEN TRUE
        WHEN "0" THEN FALSE
        ELSE ERROR("Unsupported is_residential: " || IFNULL(is_residential, "NULL"))
      END AS is_residential,
      _01,
      _02,
      _03,
      _04,
      _05,
      _06,
      _07,
      PARSE_DATE("%Y-%m-%d", effective_from) AS effective_from,
      PARSE_DATE("%Y-%m-%d", effective_to) AS effective_to,
      original_data_code,
      postal_code,
      remarks,
    FROM
      file
    QUALIFY
      IF(1=COUNT(*)OVER(PARTITION BY local_goverment_code, town_id, is_residential), TRUE, ERROR("Duplicated keys found"))
    EOF
  }
}

resource "google_project_iam_member" "health_dashboard" {
  project = var.google.project
  role    = "roles/bigquery.metadataViewer"
  member  = "user:na0@bqfun.jp"
}
