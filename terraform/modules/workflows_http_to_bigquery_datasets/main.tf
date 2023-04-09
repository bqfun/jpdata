data "google_project" "project" {}

locals {
  default                  = "wf-${replace(var.dataset_id_suffix, "_", "-")}"
  shukujitsu_us_dataset_id = "US__${var.dataset_id_suffix}"
}

resource "google_service_account" "default" {
  account_id = local.default
}

module "http_to_bigquery" {
  count = length(var.etlt)
  source                = "../../modules/workflows_http_to_bigquery"
  service_account_email = google_service_account.default.email
  simplte_url           = var.simplte_url
  simplte_name          = var.simplte_name
  dataset_id_suffix = var.dataset_id_suffix
  etlt = {
    extraction            = var.etlt[count.index].extraction
    tweaks                = var.etlt[count.index].tweaks
    transformation        = var.etlt[count.index].transformation
  }
}

module "bigquery_to_bigquery" {
  source                       = "github.com/bqfun/terraform-modules-cloud-workflows-etlt//modules/bigquery_dataset_to_bigquery_dataset"
  service_account_email        = google_service_account.default.email
  source_dataset_id            = local.shukujitsu_us_dataset_id
  destination_dataset_id       = var.dataset_id_suffix
  destination_dataset_location = "asia-northeast1"
}

resource "google_workflows_workflow" "default" {
  name            = local.default
  region          = "us-west1"
  service_account = google_service_account.default.email
  source_contents = <<-EOT
- http_to_bigquery:
    parallel:
      branches:
        - branch_none:
            steps: []
        %{ for y in module.http_to_bigquery.*.yaml ~}

        ${indent(10, y)}
        %{ endfor }
${module.bigquery_to_bigquery.yaml}
EOT
}

