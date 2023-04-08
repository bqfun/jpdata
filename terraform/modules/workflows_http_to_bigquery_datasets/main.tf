data "google_project" "project" {}

locals {
  default                  = "wf-${var.transformation.dataset_id_suffix}"
  shukujitsu_us_dataset_id = "US__${var.transformation.dataset_id_suffix}"
}

resource "google_service_account" "default" {
  account_id = local.default
}

module "http_to_cloud_storage" {
  source                = "../../modules/workflows_http_to_cloud_storage"
  service_account_email = google_service_account.default.email
  image                 = var.image
  extraction            = var.extraction
  tweaks                = var.tweaks
  loading = {
    location = "us-west1"
  }
}


module "cloud_storage_to_bigquery" {
  source                 = "github.com/bqfun/terraform-modules-cloud-workflows-etlt//modules/cloud_storage_object_to_bigquery_table"
  service_account_email  = google_service_account.default.email
  location               = "US"
  source_bucket_name     = module.http_to_cloud_storage.bucket_name
  source_object_name     = module.http_to_cloud_storage.object_name
  source_fields          = var.transformation.fields
  destination_dataset_id = local.shukujitsu_us_dataset_id
  destination_query      = var.transformation.query
}

module "bigquery_to_bigquery" {
  source                       = "github.com/bqfun/terraform-modules-cloud-workflows-etlt//modules/bigquery_dataset_to_bigquery_dataset"
  service_account_email        = google_service_account.default.email
  source_dataset_id            = local.shukujitsu_us_dataset_id
  destination_dataset_id       = var.transformation.dataset_id_suffix
  destination_dataset_location = "asia-northeast1"
}

resource "google_workflows_workflow" "default" {
  name            = local.default
  region          = "us-west1"
  service_account = google_service_account.default.email
  source_contents = <<-EOF
  ${module.http_to_cloud_storage.source_contents}
  ${module.cloud_storage_to_bigquery.yaml}
  ${module.bigquery_to_bigquery.yaml}
EOF
}
