resource "google_bigquery_dataset" "gbizinfo" {
  dataset_id                      = "gbizinfo"
  default_table_expiration_ms     = 5184000000
  default_partition_expiration_ms = 5184000000
  location                        = "asia-northeast1"
  project                         = "jpdata"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
  access {
    role          = "READER"
    group_by_email = "jpdata_gbizinfo@googlegroups.com"
  }
}
