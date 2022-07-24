resource "google_bigquery_dataset" "gbizinfo" {
  dataset_id                      = "gbizinfo"
  description                      = <<EOF
「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop）を加工して作成。

Googleグループ jpdata_gbizinfo@googlegroups.com に参加すると、データ閲覧可能です。
https://groups.google.com/g/jpdata_gbizinfo
EOF
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
    special_group = "projectReaders"
  }
  access {
    role          = "READER"
    group_by_email = "jpdata_gbizinfo@googlegroups.com"
  }
  access {
    role          = "roles/bigquery.metadataViewer"
    special_group = "allAuthenticatedUsers"
  }
}
