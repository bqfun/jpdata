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
  dataset_id = "gbizinfo"
  description = "「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop）を加工して作成"
  schedule = "0 9 * * *"
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = module.gbizinfo.bucket_name,
    url = module.httpgcs.https_trigger_url,
    dataset_id = module.gbizinfo.dataset_id,
  })
  freshness_assertion = {
    schedule = "0 10 * * *"
    tables = "['basic', 'certification', 'commendation', 'finance', 'patent', 'procurement', 'subsidy', 'workplace']",
    slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id,
  }
}

module "shukujitsu" {
  source = "../../modules/httpbq"
  project = var.google.project
  dataset_id = "shukujitsu"
  description = "「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html）を加工して作成"
  schedule = "0 6 * * *"
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = module.shukujitsu.bucket_name,
    url = module.httpgcs.https_trigger_url,
    dataset_id = module.shukujitsu.dataset_id,
  })
  freshness_assertion = {
    schedule = "0 7 * * *"
    tables = "['holidays']",
    slack_webhook_url_secret_id = google_secret_manager_secret.slack-webhook-url.id,
  }
}
