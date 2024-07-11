data "google_project" "project" {}

resource "google_project_service" "main" {
  for_each = toset([
    "analyticshub.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = data.google_project.project.number
  service            = each.key
  disable_on_destroy = false
}

resource "google_bigquery_analytics_hub_data_exchange" "jpdata" {
  project          = data.google_project.project.number
  location         = "asia-northeast1"
  data_exchange_id = "jpdata_18253a34a30"
  display_name     = "jpdata"
  description      = "BigQueryユーザコミュニティBQ Funにて、オープンデータを加工してBigQuery上で公開するエクスチェンジ。"
  primary_contact  = "https://bqfun.jp/docs/jpdata/"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "member" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata.data_exchange_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_data_exchange" "jpdata_us" {
  project          = data.google_project.project.project_id
  location         = "US"
  data_exchange_id = "us_jpdata_1877561be8d"
  display_name     = "US__jpdata"
  description      = "BigQueryユーザコミュニティBQ Funにて、オープンデータを加工してBigQuery上で公開するエクスチェンジ。"
  primary_contact  = "https://bqfun.jp/docs/jpdata/"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "member_us" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata_us.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata_us.data_exchange_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_listing" "corporate_number" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata.data_exchange_id
  listing_id       = "corporate_number_preprocessed_by_bq_fun_1843bbd5a18"
  display_name     = "Corporate Number preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = <<-EOF
  # 日本の法人情報 Corporate Number preprocessed by BQ FUN
  法人番号を持っている組織の情報をまとめたものです。

  「法人番号公表サイト」（国税庁）（https://www.houjin-bangou.nta.go.jp/ ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。
  このサービスは、国税庁法人番号システムWeb-API 機能を利用して取得した情報をもとに作成しているが、サービスの内容は国税庁によって保証されたものではない

  BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
  また、予告なく変更、削除される場合があります。

  このデータセットはCC BY 4.0で提供されています。
  https://creativecommons.org/licenses/by/4.0/legalcode.ja

  データセットの作成過程と、用いられている権利物はこちらのURLから確認できます。
  https://github.com/bqfun/jpdata
  https://github.com/bqfun/jpdata-dataform
EOF
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/houjinbangou"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "corporate_number" {
  project          = google_bigquery_analytics_hub_listing.corporate_number.project
  location         = google_bigquery_analytics_hub_listing.corporate_number.location
  data_exchange_id = google_bigquery_analytics_hub_listing.corporate_number.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.corporate_number.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

locals {
  gbizinfo = <<-EOF
  # 日本の法人情報 gBizINFO preprocessed by BQ FUN
  法人番号を持っている組織の情報をまとめたものです。

  「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。

  BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
  また、予告なく変更、削除される場合があります。

  このデータセットはCC BY 4.0で提供されています。
  https://creativecommons.org/licenses/by/4.0/legalcode.ja

  データセットの作成過程と、用いられている権利物はこちらのURLから確認できます。
  https://github.com/bqfun/jpdata
  EOF
}

resource "google_bigquery_analytics_hub_listing" "gbizinfo" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata.data_exchange_id
  listing_id       = "gbizinfo_preprocessed_by_bq_fun_18253b3389d"
  display_name     = "gBizINFO preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.gbizinfo
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/gbizinfo"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "gbizinfo" {
  project          = google_bigquery_analytics_hub_listing.gbizinfo.project
  location         = google_bigquery_analytics_hub_listing.gbizinfo.location
  data_exchange_id = google_bigquery_analytics_hub_listing.gbizinfo.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.gbizinfo.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_listing" "gbizinfo_us" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata_us.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata_us.data_exchange_id
  listing_id       = "gbizinfo_preprocessed_by_bq_fun_18253b3389d"
  display_name     = "gBizINFO preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.gbizinfo
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/US__gbizinfo"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "gbizinfo_us" {
  project          = google_bigquery_analytics_hub_listing.gbizinfo_us.project
  location         = google_bigquery_analytics_hub_listing.gbizinfo_us.location
  data_exchange_id = google_bigquery_analytics_hub_listing.gbizinfo_us.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.gbizinfo_us.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

locals {
  jp_holidays = <<-EOF
  # 日本の祝日 JP Holidays preprocessed by BQ FUN
  国民の祝日情報です。

  「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。

  BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
  また、予告なく変更、削除される場合があります。

  このデータセットはCC BY 4.0で提供されています。
  https://creativecommons.org/licenses/by/4.0/legalcode.ja

  データセットの作成過程と、用いられている権利物はこちらのURLから確認できます。
  https://github.com/bqfun/jpdata
  EOF
}

resource "google_bigquery_analytics_hub_listing" "jp_holidays" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata.data_exchange_id
  listing_id       = "jp_holidays_preprocessed_by_bq_fun_18253c4e9dc"
  display_name     = "JP Holidays preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.jp_holidays
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/shukujitsu"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "jp_holidays" {
  project          = google_bigquery_analytics_hub_listing.jp_holidays.project
  location         = google_bigquery_analytics_hub_listing.jp_holidays.location
  data_exchange_id = google_bigquery_analytics_hub_listing.jp_holidays.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.jp_holidays.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_listing" "jp_holidays_us" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata_us.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata_us.data_exchange_id
  listing_id       = "jp_holidays_preprocessed_by_bq_fun_18253c4e9dc"
  display_name     = "JP Holidays preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.jp_holidays
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/US__shukujitsu"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "jp_holidays_us" {
  project          = google_bigquery_analytics_hub_listing.jp_holidays_us.project
  location         = google_bigquery_analytics_hub_listing.jp_holidays_us.location
  data_exchange_id = google_bigquery_analytics_hub_listing.jp_holidays_us.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.jp_holidays_us.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

locals {
  base_registry_address = <<-EOF
  # アドレス・ベース・レジストリ preprocessed by BQ FUN
  日本の住所、所在地情報です。

  「アドレス・ベース・レジストリ」（デジタル庁）（https://www.digital.go.jp/policies/base_registry_address/ ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。

  BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
  また、予告なく変更、削除される場合があります。

  このデータセットはCC BY 4.0で提供されています。
  https://creativecommons.org/licenses/by/4.0/legalcode.ja

  データセットの作成過程と、用いられている権利物はこちらのURLから確認できます。
  https://github.com/bqfun/jpdata
  EOF
}

resource "google_bigquery_analytics_hub_listing" "base_registry_address" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata.data_exchange_id
  listing_id       = "base_registry_address_preprocessed_by_bq_fun_123456789ab"
  display_name     = "Address base registry preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.base_registry_address
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/base_registry_address"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "base_registry_address" {
  project          = google_bigquery_analytics_hub_listing.base_registry_address.project
  location         = google_bigquery_analytics_hub_listing.base_registry_address.location
  data_exchange_id = google_bigquery_analytics_hub_listing.base_registry_address.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.base_registry_address.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_listing" "base_registry_address_us" {
  project          = google_bigquery_analytics_hub_data_exchange.jpdata_us.project
  location         = google_bigquery_analytics_hub_data_exchange.jpdata_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.jpdata_us.data_exchange_id
  listing_id       = "base_registry_address_preprocessed_by_bq_fun_123456789ab"
  display_name     = "Address base registry preprocessed by BQ FUN"
  primary_contact  = "https://bqfun.jp/"
  documentation    = local.base_registry_address
  categories       = ["CATEGORY_PUBLIC_SECTOR"]

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/US__base_registry_address"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "base_registry_address_us" {
  project          = google_bigquery_analytics_hub_listing.base_registry_address_us.project
  location         = google_bigquery_analytics_hub_listing.base_registry_address_us.location
  data_exchange_id = google_bigquery_analytics_hub_listing.base_registry_address_us.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.base_registry_address_us.listing_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}
