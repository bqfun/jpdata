resource "google_storage_bucket" "source" {
  name     = "${var.google.project}-source"
  location = "asia-northeast1"
  uniform_bucket_level_access = true
}

module "gbizinfo" {
  source = "../../modules/httpbq"
  project = var.google.project
  project_number = var.google.number
  dataset_id = "gbizinfo"
  description = "「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop）を加工して作成"
  schedule = "0 9 * * *"
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = google_storage_bucket.source.name,
  })
}

module "shukujitsu" {
  source = "../../modules/httpbq"
  project = var.google.project
  project_number = var.google.number
  dataset_id = "shukujitsu"
  description = "「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html）を加工して作成"
  schedule = "0 6 * * *"
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = google_storage_bucket.source.name,
  })
}

resource "google_project_iam_member" "dataform" {
  for_each = toset([
    "roles/dataform.serviceAgent",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/bigquery.connectionAdmin",
  ])
  project = var.google.project
  role    = each.key
  member  = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

module "dataform" {
  source = "../../modules/dataform"
  project = var.google.project
  connection_id = "${google_bigquery_connection.main.project}.${google_bigquery_connection.main.location}.${google_bigquery_connection.main.connection_id}"
  bucket_gbizinfo = module.gbizinfo.bucket_name
  bucket_shukujitsu = module.shukujitsu.bucket_name
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
