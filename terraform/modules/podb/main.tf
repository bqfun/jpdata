data "google_project" "project" {}

resource "google_storage_bucket" "main" {
  name     = "podb"
  location = "us-central1"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

resource "google_storage_bucket_iam_member" "main" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${var.cloud_storage_service_account}"
}

data "google_project" "main" {
}

resource "google_project_iam_member" "main" {
  project = data.google_project.main.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.main.number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
}

resource "google_service_account" "podb" {
  account_id = "scheduled-query-podb"
}

resource "google_storage_bucket_iam_member" "podb" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.podb.email}"
}

resource "google_project_iam_member" "podb" {
  project = data.google_project.main.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.podb.email}"
}

resource "google_bigquery_data_transfer_config" "main" {
  depends_on = [google_project_iam_member.main]

  display_name         = "podb"
  location             = "US"
  data_source_id       = "scheduled_query"
  schedule             = "every day 15:00"
  service_account_name = google_service_account.podb.email
  params = {
    query = <<-EOT
    DECLARE paths ARRAY<STRUCT<path STRING, url STRING>> DEFAULT [
      ("PODB_JAPANESE_CALENDAR_DATA/E_PODB/E_JAPAN_CALENDAR", "https://podb.truestar.co.jp/archives/cal-data/calendar"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_FD20", "https://podb.truestar.co.jp/archives/city-data/ci_fd20"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_HT15", "https://podb.truestar.co.jp/archives/city-data/ci_ht"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_HT20", "https://podb.truestar.co.jp/archives/city-data/ci_ht"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PA15", "https://podb.truestar.co.jp/archives/city-data/ci_pa"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PA20", "https://podb.truestar.co.jp/archives/city-data/ci_pa"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PI15", "https://podb.truestar.co.jp/archives/city-data/ci_pi"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PI20_2", "https://podb.truestar.co.jp/archives/city-data/ci_pi"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PI20", "https://podb.truestar.co.jp/archives/city-data/ci_pi"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PO15", "https://podb.truestar.co.jp/archives/city-data/ci_po"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PO20_2", "https://podb.truestar.co.jp/archives/city-data/ci_po"),
      ("PODB_JAPANESE_CITY_DATA/E_PODB/E_CI_PO20", "https://podb.truestar.co.jp/archives/city-data/ci_po"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_BASIC", "https://podb.truestar.co.jp/archives/corp-data/basic"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_CERTIFICATION", "https://podb.truestar.co.jp/archives/corp-data/certification"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_COMMENDATION", "https://podb.truestar.co.jp/archives/corp-data/commendation"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_EMPLOYEE", "https://podb.truestar.co.jp/archives/corp-data/employees"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_FINANCE", "https://podb.truestar.co.jp/archives/corp-data/finance"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_PATENT", "https://podb.truestar.co.jp/archives/corp-data/patent"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_PROCUREMENT", "https://podb.truestar.co.jp/archives/corp-data/procurement"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_STOCKCODE", "https://podb.truestar.co.jp/archives/corp-data/stockcode"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_SUBSIDY", "https://podb.truestar.co.jp/archives/corp-data/subsidy"),
      ("PODB_JAPANESE_CORPORATE_DATA/E_PODB/CORP_WORKPLACE", "https://podb.truestar.co.jp/archives/corp-data/workspace"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_PP", "https://podb.truestar.co.jp/archives/land-price-data/lp_pp"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_PP22", "https://podb.truestar.co.jp/archives/land-price-data/lp_pp"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_PP23", "https://podb.truestar.co.jp/archives/land-price-data/lp_pp"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_TS", "https://podb.truestar.co.jp/archives/land-price-data/lp_ts"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_TS22", "https://podb.truestar.co.jp/archives/land-price-data/lp_ts"),
      ("PODB_JAPANESE_LAND_PRICE_DATA/E_PODB/E_LP_TS23", "https://podb.truestar.co.jp/archives/land-price-data/lp_ts"),
      ("PODB_JAPANESE_MEDICAL_DATA/E_PODB/E_MD_A1ST20", "https://podb.truestar.co.jp/archives/medical-data/md_a1st20"),
      ("PODB_JAPANESE_MEDICAL_DATA/E_PODB/E_MD_A2ND20", "https://podb.truestar.co.jp/archives/medical-data/md_a2nd20"),
      ("PODB_JAPANESE_MEDICAL_DATA/E_PODB/E_MD_A3RD20", "https://podb.truestar.co.jp/archives/medical-data/md_a3rd20"),
      ("PODB_JAPANESE_MEDICAL_DATA/E_PODB/E_MD_IP20", "https://podb.truestar.co.jp/archives/medical-data/md_ip20"),
      ("PODB_JAPANESE_MESH_DATA/E_PODB/E_MS_PF18_1KM", "https://podb.truestar.co.jp/archives/mesh-data/ms_pf18_1km"),
      ("PODB_JAPANESE_MESH_DATA/E_PODB/E_MS_PP18_1KM", "https://podb.truestar.co.jp/archives/mesh-data/ms_pp18_1km"),
      ("PODB_JAPANESE_MESH_DATA/E_PODB/E_MS_PP18_500M", "https://podb.truestar.co.jp/archives/mesh-data/ms_pp18_500m"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_FD20", "https://podb.truestar.co.jp/archives/pref-data/pr_fd20"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_HT15", "https://podb.truestar.co.jp/archives/pref-data/pr_ht"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_HT20", "https://podb.truestar.co.jp/archives/pref-data/pr_ht"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PA15", "https://podb.truestar.co.jp/archives/pref-data/pr_pa"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PA20", "https://podb.truestar.co.jp/archives/pref-data/pr_pa"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PI15", "https://podb.truestar.co.jp/archives/pref-data/pr_pi"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PI20_2", "https://podb.truestar.co.jp/archives/pref-data/pr_pi"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PI20", "https://podb.truestar.co.jp/archives/pref-data/pr_pi"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PO15", "https://podb.truestar.co.jp/archives/pref-data/pr_po"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PO20_2", "https://podb.truestar.co.jp/archives/pref-data/pr_po"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PO20", "https://podb.truestar.co.jp/archives/pref-data/pr_po"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_PTS", "https://podb.truestar.co.jp/archives/pref-data/pr_pts"),
      ("PODB_JAPANESE_PREFECTURE_DATA/E_PODB/E_PR_TB", "https://podb.truestar.co.jp/archives/pref-data/pr_tb"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR_1", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR_2", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_2"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR20_1", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR20_2", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_2"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR22_1", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PR22_2", "https://podb.truestar.co.jp/archives/sr-data/sr_pr_2"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS_1", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS_2", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_2"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS20_1", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS20_2", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_2"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS22_1", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_1"),
      ("PODB_JAPANESE_STATION_AND_RAILWAY_DATA/E_PODB/E_SR_PS22_2", "https://podb.truestar.co.jp/archives/sr-data/sr_ps_2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_GEO", "https://podb.truestar.co.jp/archives/str-data/st_cs20_geo"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_MST", "https://podb.truestar.co.jp/archives/str-data/st_cs20_mst"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T02", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t02"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T03", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t03"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T04", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t04"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T05_1", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t05_1"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T05_2", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t05_2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T06_1", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t06_1"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T06_2", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t06_2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T06_3", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t06_3"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T07_1", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t07_1"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T07_2", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t07_2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T07_3", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t07_3"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T08_1", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t08_1"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T08_2", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t08_2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T08_3", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t08_3"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T09", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t09"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T10", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t10"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T11", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t11"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T12", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t12"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T13", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t13"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T14", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t14"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T15", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t15"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T18", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t18"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_CS20_T19", "https://podb.truestar.co.jp/archives/str-data/st_cs20_t19"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_FD15", "https://podb.truestar.co.jp/archives/str-data/st_fd2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_FD20", "https://podb.truestar.co.jp/archives/str-data/st_fd2"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_HT15", "https://podb.truestar.co.jp/archives/str-data/st_ht"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_HT20", "https://podb.truestar.co.jp/archives/str-data/st_ht"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PA15", "https://podb.truestar.co.jp/archives/str-data/st_pa"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PA20", "https://podb.truestar.co.jp/archives/str-data/st_pa"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PI15", "https://podb.truestar.co.jp/archives/str-data/st_pi"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PI20", "https://podb.truestar.co.jp/archives/str-data/st_pi"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PO15", "https://podb.truestar.co.jp/archives/str-data/st_po1"),
      ("PODB_JAPANESE_STREET_DATA/E_PODB/E_ST_PO20", "https://podb.truestar.co.jp/archives/str-data/st_po1"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_2DT", "https://podb.truestar.co.jp/archives/weather-data/wt_2dt"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_F1W", "https://podb.truestar.co.jp/archives/weather-data/wt_f1w"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_F3D", "https://podb.truestar.co.jp/archives/weather-data/wt_f3d"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_MD", "https://podb.truestar.co.jp/archives/weather-data/wt_day"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_MM", "https://podb.truestar.co.jp/archives/weather-data/wt_month"),
      ("PODB_JAPANESE_WEATHER_DATA/E_PODB/E_WT_N1W", "https://podb.truestar.co.jp/archives/weather-data/wt_n1w")
    ];
    DECLARE l INT64 DEFAULT ARRAY_LENGTH(paths);
    DECLARE i INT64 DEFAULT 0;
    DECLARE path STRING;
    DECLARE dataset_id STRING;
    DECLARE description STRING;
    DECLARE friendly_name STRING;
    DECLARE table_id STRING;
    DECLARE column_list STRING;

    WHILE i < l DO
      SET path = paths[i].path;
      SET description = paths[i].url;
      SET dataset_id = SPLIT(path, "/")[0] || "__US";
      EXECUTE IMMEDIATE
        "CREATE SCHEMA IF NOT EXISTS " || dataset_id;
      EXECUTE IMMEDIATE
        "LOAD DATA OVERWRITE TEMP TABLE information_schema_tables_copy FROM FILES (format = 'PARQUET', uris = ['gs://podb/INFORMATION_SCHEMA/TABLES/"
          || SPLIT(path, "/")[0] || "/E_PODB/*.snappy.parquet'])";
      EXECUTE IMMEDIATE
        "LOAD DATA OVERWRITE TEMP TABLE information_schema_columns_copy FROM FILES (format = 'PARQUET', uris = ['gs://podb/INFORMATION_SCHEMA/COLUMNS/"
          || SPLIT(path, "/")[0] || "/E_PODB/*.snappy.parquet'])";

      EXECUTE IMMEDIATE
        "SELECT COMMENT FROM information_schema_tables_copy"
          || " WHERE TABLE_CATALOG = '"
          || SPLIT(path, "/")[0]
          || "' AND TABLE_SCHEMA = '"
          || SPLIT(path, "/")[1]
          || "' AND TABLE_NAME = '"
          || SPLIT(path, "/")[2]
          || "'" INTO friendly_name;

      SET table_id = IFNULL(REGEXP_EXTRACT(SPLIT(path, "/")[2], "E_(.+)"), SPLIT(path, "/")[2]);

      EXECUTE IMMEDIATE
        "ALTER TABLE IF EXISTS " || dataset_id || "." || table_id
        || " SET OPTIONS(friendly_name = '''" || friendly_name || "''', description = '''" || description || "''')";

      EXECUTE IMMEDIATE
        """
          SELECT
            STRING_AGG(
              '`' || REPLACE(REPLACE(REPLACE(COLUMN_NAME, ",", ""), "(", ""), ")", "") || '` '
              || CASE
                    WHEN TABLE_NAME = "E_LP_PP23" AND COLUMN_NAME = "EXTRA_FLOOR_AREA_RATIO" THEN "STRING"
                    WHEN DATA_TYPE = "TEXT" THEN "STRING"
                    WHEN DATA_TYPE = "FLOAT" THEN "FLOAT64"
                    WHEN DATA_TYPE = "NUMBER" THEN "NUMERIC"
                    WHEN DATA_TYPE = "GEOGRAPHY" THEN "STRING"
                    WHEN DATA_TYPE = "BOOLEAN" THEN "BOOL"
                    WHEN DATA_TYPE = "TIMESTAMP_NTZ" THEN "DATETIME"
                    ELSE DATA_TYPE
              END
              || " OPTIONS(description='''" || IFNULL(COMMENT, "") || "''')", "," ORDER BY ORDINAL_POSITION
            )
          FROM
            information_schema_columns_copy
          WHERE
        """
          || "TABLE_CATALOG = '" || SPLIT(path, "/")[0]
          || "' AND TABLE_SCHEMA = '" || SPLIT(path, "/")[1]
          || "' AND TABLE_NAME = '" || SPLIT(path, "/")[2]
          || "'" INTO column_list;
      EXECUTE IMMEDIATE
        "LOAD DATA OVERWRITE "
          || dataset_id || "." || table_id
          || IFNULL(" (" || column_list || ")", "")
          || " OPTIONS(friendly_name='''"
          || friendly_name
          || "''', description='''"
          || description
          || "''') FROM FILES (format = 'PARQUET', uris = ['gs://podb/" || path || "/*.snappy.parquet'])";
      SET i = i + 1;
    END WHILE;

    EOT
  }
}

resource "google_bigquery_analytics_hub_data_exchange" "podb_us" {
  project          = "jpdata"
  location         = "US"
  data_exchange_id = "podb__us"
  display_name     = "podb__us"
  description      = "BigQuery ユーザコミュニティ BQ Fun にて、株式会社 truestar のデータ提供サービス Prepper Open Data Bank の BigQuery クローンを提供する。"
  primary_contact  = "https://bqfun.jp/docs/podb/"

  lifecycle {
    prevent_destroy = true
  }
}


locals {
  listings = [
    {
      url = "https://podb.truestar.co.jp/archives/pref-data"
      display_name = "JAPANESE PREFECTURE DATA"
      dataset_id = "PODB_JAPANESE_PREFECTURE_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      1．旧C&Sのビュー
      2023年9月より、従来JAPANESE CENSUS&SPATIAL(略称：旧C&S)で公開していた都道府県レベルのデータが含まれます。

      また、以下について、近日公開予定です。

      Japanese Prefecture Dataは、政府統計ポータルサイト「e-stat」で公開されている日本の都道府県レベルの統計・空間データを、データ分析ですぐに活用できる形にtruestarが収集・加工したものです。このデータベースには、性別、年齢層別などに分類された総人口・労働者人口データなど様々な統計情報が含まれており、都道府県単位での分析で必要なデータを豊富に提供しています。

      調査統計量データとして、国勢調査と住宅・土地統計調査など、調査に応じてテーブルを区分せずに、一つのテーブル「都道府県調査統計量データ【PR_ST】」にまとめました。「都道府県調査統計量データ【PR_ST】」で示す各カラムの内容がわかりやすいように、統計調査属性情報のテーブル「都道府県統計量マスタ【PR_ST_MST】と統計調査概要情報のテーブル「都道府県調査マスタ【PR_TB_MST】」も作成しました。

      都道府県コードと都道府県名をまとめた「都道府県マスタ【PR_MST】」、国土地理院の役所情報に基づく「都道府県代表点データ【PR_GEO_PT】」、国土数値情報のポリゴンに基づく「都道府県ポリゴンデータ【PR_GEO_PG】」を地理情報として用意しています。

      また、ユーザーが必要な統計調査だけ使えるように、各統計調査の分類別や調査年別に最低限のカラムを付与したビューも共有しています。更に、都道府県マスタ【PR_MST】と結合し、都道府県コードと都道府県名が付与されています。

      2．本番公開分（E_PODB、J_PODBスキーマ）
      従来JAPANESE CENSUS&SPATIAL（略称：旧C&S）で公開していた都道府県レベルのデータも含まれます。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/city-data"
      display_name = "JAPANESE CITY DATA"
      dataset_id = "PODB_JAPANESE_CITY_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      1．BETA版公開分
      JAPANESE CITY DATAは、政府統計ポータルサイト「e-stat」で公開されている日本の市区町村レベルの統計・空間データを、データ分析ですぐに活用できる形にtruestarが収集・加工したものです。このデータベースには、性別、年齢層別などに分類された総人口・労働者人口データなど様々な統計情報が含まれており、市区町村単位での分析で必要なデータを豊富に提供しています。

      調査統計量データとして、国勢調査と住宅・土地統計調査など、調査に応じてテーブルを区分せずに、一つのテーブル「市区町村調査統計量データ【CI_ST】」にまとめました。「市区町村調査統計量データ【CI_ST】」で示す各カラムの内容がわかりやすいように、統計調査属性情報のテーブル「市区町村統計量マスタ【CI_ST_MST】と統計調査概要情報のテーブル「市区町村調査マスタ【CI_TB_MST】」も作成しました。

      市区町村コードと市区町村名をまとめた「市区町村マスタ【CI_MST】」、国土地理院の役所情報に基づく「市区町村代表点データ【CI_GEO_PT】」、国土数値情報のポリゴンに基づく「市区町村ポリゴンデータ【CI_GEO_PG】」を地理情報として用意しています。

      また、ユーザーが必要な統計調査だけ使えるように、各統計調査の分類別や調査年別に最低限のカラムを付与したビューも共有しています。更に、市区町村マスタ【CI_MST】と結合し、市区町村コードと市区町村名が付与されています。

      2．本番公開分（E_PODB、J_PODBスキーマ）
      従来JAPANESE CENSUS&SPATIAL（略称：旧C&S）で公開していた市区町村レベルのデータも含まれます。

      ※市区町村代表点データは国土地理院の役所・役場の緯度・経度データを利用しています。しかし現在、ウェブサイトの更新に伴い、出典データにアクセスできなくなっております。次回国勢調査時においては、代替のオープンデータを使用して情報をお届けする予定です。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/str-data"
      display_name = "JAPANESE STREET DATA"
      dataset_id = "PODB_JAPANESE_STREET_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      ※全データ本番公開済みです。BETA版は2023年末にクローズ予定です。

      Japanese Street Dataは、政府統計ポータルサイト「e-stat」で公開されている日本の国勢調査の町丁目（小地域）レベルの統計・空間データを、データ分析ですくに活用できる形にtruestarが収集・加工したものです。
      このデータには、性別、年齢層別、持ち家別に分類された総人口データ、学生・労働者人口データなどが含まれており、町丁目単位で利用することが可能です。分析者はこのデータを利用して、日本全国の人口動態や地理的要因について、高い粒度で様々な分析を容易に行うことができます。
      BIやGISツールを用いれば、町丁目データを活用したマッピング、分析、レポート作成が簡単に行え、地域ごとの市場ニーズ・特性の分析、需要予測など、様々な用途に活用することができます。

      SQLでの分析やシステム連携時に扱いやすいカラム名を持つテーブルと、TableauなどのBIツールで利用しやすい日本語および英語のカラム名にそれぞれ変更したビュー、計三種類をご用意しています。

      「町丁目ジオデータ【ST_CS20_GEO】」及び「町丁目マスタデータ【ST_CS20_MST】」では、実際にTableauを用いてデータを可視化したYouTube動画もご紹介しています。

      従来JAPANESE CENSUS&SPATIAL（略称：旧C&S）で公開していた町丁目レベルのデータも含まれます。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/mesh-data"
      display_name = "JAPANESE MESH DATA"
      dataset_id = "PODB_JAPANESE_MESH_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Mesh Dataは、日本全国のメッシュ別の人流データや将来推計人口データを提供しています。（メッシュのみのデータセットも提供予定。）
      元データが所有する行政区域コードから都道府県名、市区町村名を付与しています。年齢区分や都道府県名、市区町村名でフィルタリングをすれば容易に必要な情報のみを抽出できます。
      自社店舗の商圏、進出予定地などのPOIと重ね合わせることで、需要予測等によりビジネスインパクトを分析することができます。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/sr-data"
      display_name = "JAPANESE STATION AND RAILWAY DATA"
      dataset_id = "PODB_JAPANESE_STATION_AND_RAILWAY_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Station and Railway Dataは、日本全国の鉄道の路線や駅について、ポイント及びポリラインデータを保有しています。
      Snowflake Data Marketplaceに展開している他のデータセットと空間結合して分析を行うことで、最寄駅の特定や距離計算などが容易に可能です。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/weather-data"
      display_name = "JAPANESE WEATHER DATA"
      dataset_id = "PODB_JAPANESE_WEATHER_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Weather Dataは、気象庁の公表する全国の天気情報を提供しています。
      明日までの詳細な天気情報を提供するデータセット、1週間後までの降水確率などの基本情報を提供するデータセットなどを提供しています。また、それぞれのデータセットを結合することで、簡単に分析が行えます。

      PODBの気象データは、気象業務法で定める予報業務許可の対象にはなりません。「気象庁が出した予報をそのまま掲載する・伝えるまたはそれを解説する」ものであり、また出展の明記もあるため、特に問題ないと気象庁総務部総務課から直接確認を得て搭載しています。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/land-price-data"
      display_name = "JAPANESE LAND PRICE DATA"
      dataset_id = "PODB_JAPANESE_LAND_PRICE_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Land Price Dataは、日本全国における、時系列の地価情報とその土地の最新の属性情報を保持しており、全国の土地間の比較が可能です。時系列の情報も１レコードに横持ちしたデータセットと、時系列の地価情報を縦持ちしたデータを共有しており、カラム名 PODB_LAND_PRICE_ID で結合をしてご活用いただくことが可能です。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/medical-data"
      display_name = "JAPANESE MEDICAL DATA"
      dataset_id = "PODB_JAPANESE_MEDICAL_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Medical Dataは、日本全国の医療機関の位置情報と診療科目や病床数などの属性情報や、日本の医療圏の情報を提供しています。
      Snowflake Data Marketplaceに展開している他のデータセットと空間結合して分析を行うことで、最寄の医療機関の特定や距離計算などが容易に可能です。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/corp-data"
      display_name = "JAPANESE CORPORATE DATA"
      dataset_id = "PODB_JAPANESE_CORPORATE_DATA"
      documentation = <<-EOT
      Prepper Open Data Bankは、様々な日本のオープンデータをデータプレップなしですぐ加工できるようにして提供しています。

      Japanese Corporate Dataには、経済産業省のgBizINFOの公開データを元に、truestarが加工した日本国内の法人情報が入っています。
      gBizINFOには、国税庁、金融庁、厚生労働省、総務省など、政府保有のデータが複数連携・集約されており、それらのデータをダウンロードやAPIの仕様を理解することなく利活用できます。

      また、2023年3月から、株式会社TSUIDE及び法人番号株式会社が収集・加工した日本年金機構の従業員数（被保険者数）データを追加致しました。

      共有する法人情報には全て法人番号が含まれており、法人番号をキーに任意の企業の情報を簡単に抽出することが可能です。

      こちらに含まれるデータセットは以下の通りです。

      「日本法人の基本情報【CORP_BASIC】」のページでは、法人番号のデータをSalesforceに連携する方法を紹介したYoutube動画を載せています。

      【重要】お知らせ(2024.1.5)
      EMPLOYEEデータの収集・加工にかかるコスト負担が非常に高いことから、2024年2月の更新後、PODB上での運用方法を変更することとなりました。詳細は「日本法人の従業員数【CORP_EMPLOYEE】」ページからご確認ください。
      EOT
    },
    {
      url = "https://podb.truestar.co.jp/archives/cal-data"
      display_name = "JAPANESE CALENDAR DATA"
      dataset_id = "PODB_JAPANESE_CALENDAR_DATA"
      documentation = <<-EOT
      Japanese Calendar Data には、日付や曜日情報に加え、内閣府から毎年2月に発表される祝日と振替休日や、土日祝、平日、GW、年末年始、休前日など、様々な事業のマーケティング活動に影響のある軸で予めフラグ化するなど、日次データを用いた機械学習などのデータ分析ですぐに活用できる形に加工しています。

      例年2月に翌年末までの祝日・振替休日の情報が公開されるため、その後に翌年分を更新します。

      日本のカレンダー【JAPAN_CALENDAR】では2010年1月1日からデータを保持しています。SQLでの分析やシステム連携時に扱いやすいカラム名を持つテーブルと、TableauなどのBIツールで利用しやすい日本語および英語のカラム名にそれぞれ変更したビュー、計三種類をご用意しています。
      EOT
    }
  ]
  common_documentation = <<-EOT
  --
  株式会社 truestar が抽出、加工したデータ提供サービス Prepper Open Data Bank の BigQuery クローンです。
  BigQuery ユーザコミュニティ BQ FUN が加工して作成しています。BQ FUN および株式会社 truestar は、利用者が本コンテンツを用いて行う一切の責任を負いません。
  また、予告なく変更、削除される場合があります。

  このデータセットはCC BY 4.0で提供されています。
  https://creativecommons.org/licenses/by/4.0/legalcode.ja
  EOT
}

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "member_us" {
  project          = google_bigquery_analytics_hub_data_exchange.podb_us.project
  location         = google_bigquery_analytics_hub_data_exchange.podb_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.podb_us.data_exchange_id
  role             = "roles/analyticshub.subscriber"
  member           = "allAuthenticatedUsers"
}

resource "google_bigquery_analytics_hub_listing" "podb_us" {
  for_each = { for index, s in local.listings : "${s.dataset_id}__US" => s }
  project          = google_bigquery_analytics_hub_data_exchange.podb_us.project
  location         = google_bigquery_analytics_hub_data_exchange.podb_us.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.podb_us.data_exchange_id
  listing_id       = replace(lower(each.value.display_name), " ", "_")
  display_name     = each.value.display_name
  primary_contact  = "https://bqfun.jp/docs/podb/"
  documentation    = "${each.value.documentation}\n\n詳細な定義: ${each.value.url}\n\n${local.common_documentation}"

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/${each.value.dataset_id}__US"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# asia-northeast1

resource "google_service_account" "cross_region" {
  account_id = "podb-cross-region-copy"
}

resource "google_bigquery_dataset" "cross_region" {
  for_each = { for index, s in local.listings : s.dataset_id => s }
  dataset_id = each.value.dataset_id
  location   = "asia-northeast1"
}

resource "google_bigquery_data_transfer_config" "cross_region" {
  for_each = { for index, s in local.listings : s.dataset_id => s }
  display_name           = each.value.dataset_id
  location               = "asia-northeast1"
  data_source_id         = "cross_region_copy"
  schedule               = "every day 16:00"
  destination_dataset_id = each.value.dataset_id
  params = {
    source_dataset_id           = each.value.dataset_id
    overwrite_destination_table = true
  }
  schedule_options {
    disable_auto_scheduling = true
  }
  service_account_name = google_service_account.cross_region.email
  depends_on = [
    google_bigquery_dataset.cross_region,
  ]
}

resource "google_project_iam_member" "cross_region" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.cross_region.email}"
  # To create the copy transfer, you need the following on the project:
  #   - bigquery.transfers.update
  #   - bigquery.jobs.create
  # https://cloud.google.com/bigquery/docs/copying-datasets#required_permissions
}

resource "google_bigquery_analytics_hub_data_exchange" "podb" {
  project          = "jpdata"
  location         = "asia-northeast1"
  data_exchange_id = "podb"
  display_name     = "podb"
  description      = "BigQuery ユーザコミュニティ BQ Fun にて、株式会社 truestar のデータ提供サービス Prepper Open Data Bank の BigQuery クローンを提供する。"
  primary_contact  = "https://bqfun.jp/docs/podb/"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_analytics_hub_listing" "podb" {
  for_each = { for index, s in local.listings : s.dataset_id => s }
  project          = google_bigquery_analytics_hub_data_exchange.podb.project
  location         = google_bigquery_analytics_hub_data_exchange.podb.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.podb.data_exchange_id
  listing_id       = replace(lower(each.value.display_name), " ", "_")
  display_name     = each.value.display_name
  primary_contact  = "https://bqfun.jp/docs/podb/"
  documentation    = "${each.value.documentation}\n\n詳細な定義: ${each.value.url}\n\n${local.common_documentation}"

  bigquery_dataset {
    dataset = "projects/${data.google_project.project.number}/datasets/${each.value.dataset_id}"
  }
  lifecycle {
    prevent_destroy = true
  }
  depends_on = [
    google_bigquery_dataset.cross_region,
  ]
}
