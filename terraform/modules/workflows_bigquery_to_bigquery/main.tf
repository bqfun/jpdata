data "google_project" "project" {}

resource "random_uuid" "default" {}

resource "google_project_iam_member" "default" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${var.service_account_email}"
  # To create the copy transfer, you need the following on the project:
  #   - bigquery.transfers.update
  #   - bigquery.jobs.create
  # On the source dataset, you need the following:
  #   - bigquery.datasets.get
  #   - bigquery.tables.list
  # On the destination dataset, you need the following:
  #   - bigquery.datasets.get
  #   - bigquery.datasets.update
  #   - bigquery.tables.create
  #   - bigquery.tables.list
  # https://cloud.google.com/bigquery/docs/copying-datasets#required_permissions
}

resource "google_bigquery_data_transfer_config" "default" {
  display_name           = "${var.source_dataset_id}-${var.destination_dataset_id}"
  location               = var.destination_dataset_location
  data_source_id         = "cross_region_copy"
  destination_dataset_id = var.destination_dataset_id
  params = {
    source_dataset_id = var.source_dataset_id
    overwrite_destination_table = true
  }
  schedule_options {
    disable_auto_scheduling = true
  }
  service_account_name = var.service_account_email
}
