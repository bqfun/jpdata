provider "google" {
  project = var.project
  zone = "asia-northeast1-a"
}

module "gbizinfo" {
  source = "../../modules/httpbq"
  project = var.project
  dataset_id = "gbizinfo"
  description = "「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop）を加工して作成"
  schedule = "0 10 * * *"
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = module.gbizinfo.bucket_name,
    url = google_cloudfunctions_function.httpgcs.https_trigger_url,
    dataset_id = module.gbizinfo.dataset_id,
  })
}

module "shukujitsu" {
  source = "../../modules/httpbq"
  project = var.project
  dataset_id = "shukujitsu"
  description = "「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html）を加工して作成"
  schedule = "0 6 * * *"
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = module.shukujitsu.bucket_name,
    url = google_cloudfunctions_function.httpgcs.https_trigger_url,
    dataset_id = module.shukujitsu.dataset_id,
  })
}
