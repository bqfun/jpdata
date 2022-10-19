module "httpgcs" {
  source = "../../modules/httpgcs"
  project = var.google.project
  region = var.google.region
}

resource "google_secret_manager_secret" "slack-webhook-url" {
  secret_id = "slack-webhook-url"

  replication {
    automatic = true
  }
}

module "gbizinfo" {
  source = "../../modules/httpbq"
  project = var.google.project
  project_number = var.google.number
  dataset_id = "gbizinfo"
  description = "「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop）を加工して作成"
  schedule = "0 9 * * *"
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = module.gbizinfo.bucket_name,
    repository = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    url = module.httpgcs.https_trigger_url,
    slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id,
  })
  slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id
}

module "shukujitsu" {
  source = "../../modules/httpbq"
  project = var.google.project
  project_number = var.google.number
  dataset_id = "shukujitsu"
  description = "「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html）を加工して作成"
  schedule = "0 6 * * *"
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = module.shukujitsu.bucket_name,
    repository = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    url = module.httpgcs.https_trigger_url,
    slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id,
  })
  slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id
}

resource "google_project_iam_member" "dataform" {
  for_each = toset([
    "roles/dataform.serviceAgent",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/storage.objectViewer"
  ])
  project = var.google.project
  role    = each.key
  member  = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

module "dataform" {
  source = "../../modules/dataform"
  project = var.google.project
  name = "dataform"
  slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id
}