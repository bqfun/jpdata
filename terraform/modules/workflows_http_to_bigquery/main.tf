resource "random_uuid" "default" {}

locals {
  shukujitsu_us_dataset_id = "US__${var.dataset_id_suffix}"
}

module "http_to_cloud_storage" {
  source                = "../../modules/workflows_http_to_cloud_storage"
  service_account_email = var.service_account_email
  extraction            = var.etlt.extraction
  tweaks                = var.etlt.tweaks
  loading = {
    location = "us-west1"
  }
  simplte_url           = var.simplte_url
  simplte_name          = var.simplte_name
}

module "cloud_storage_to_bigquery" {
  source                 = "github.com/bqfun/terraform-modules-cloud-workflows-etlt//modules/cloud_storage_object_to_bigquery_table"
  service_account_email  = var.service_account_email
  location               = "US"
  source_bucket_name     = module.http_to_cloud_storage.bucket_name
  source_object_name     = module.http_to_cloud_storage.object_name
  source_fields          = var.etlt.transformation.fields
  destination_dataset_id = local.shukujitsu_us_dataset_id
  destination_query      = var.etlt.transformation.query
}
