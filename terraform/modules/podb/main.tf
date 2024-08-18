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
    DECLARE paths ARRAY<STRING> DEFAULT [
      "PODB_JAPANESE_CALENDAR_DATA/J_PODB/J_JAPAN_CALENDAR",

      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_FD20",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_HT15",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_HT20",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PA15",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PA20",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PI15",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PI20_2",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PI20",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PO15",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PO20_2",
      "PODB_JAPANESE_CITY_DATA/J_PODB/J_CI_PO20",

      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_BASIC",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_CERTIFICATION",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_COMMENDATION",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_EMPLOYEE",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_FINANCE",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_PATENT",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_PROCUREMENT",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_STOCKCODE",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_SUBSIDY",
      "PODB_JAPANESE_CORPORATE_DATA/J_PODB/J_CORP_WORKPLACE",

      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_PP",
      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_PP22",
      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_PP23",
      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_TS",
      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_TS22",
      "PODB_JAPANESE_LAND_PRICE_DATA/J_PODB/J_LP_TS23",

      "PODB_JAPANESE_MEDICAL_DATA/J_PODB/J_MD_A1ST20",
      "PODB_JAPANESE_MEDICAL_DATA/J_PODB/J_MD_A2ND20",
      "PODB_JAPANESE_MEDICAL_DATA/J_PODB/J_MD_A3RD20",
      "PODB_JAPANESE_MEDICAL_DATA/J_PODB/J_MD_IP20",

      "PODB_JAPANESE_MESH_DATA/J_PODB/J_MS_PF18_1KM",
      "PODB_JAPANESE_MESH_DATA/J_PODB/J_MS_PP18_1KM",
      "PODB_JAPANESE_MESH_DATA/J_PODB/J_MS_PP18_500M",

      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_FD20",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_HT15",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_HT20",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PA15",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PA20",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PI15",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PI20_2",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PI20",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PO15",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PO20_2",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PO20",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_PTS",
      "PODB_JAPANESE_PREFECTURE_DATA/J_PODB/J_PR_TB",

      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PR_1",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PR_2",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PR20_1",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PR20_2",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PS_1",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PS_2",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PS20_1",
      "PODB_JAPANESE_STATION_AND_RAILWAY_DATA/J_PODB/J_SR_PS20_2",

      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_GEO",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_MST",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T02",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T03",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T04",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T05_1",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T05_2",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T06_1",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T06_2",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T06_3",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T07_1",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T07_2",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T07_3",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T08_1",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T08_2",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T08_3",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T09",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T10",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T11",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T12",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T13",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T14",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T18",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_CS20_T19",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_FD15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_FD20",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_HT15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_HT20",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PA15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PA20",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PI15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PI20",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PO15",
      "PODB_JAPANESE_STREET_DATA/J_PODB/J_ST_PO20",

      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_2DT",
      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_F1W",
      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_F3D",
      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_MD",
      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_MM",
      "PODB_JAPANESE_WEATHER_DATA/J_PODB/J_WT_N1W"
    ];
    DECLARE l INT64 DEFAULT ARRAY_LENGTH(paths);
    DECLARE i INT64 DEFAULT 0;
    DECLARE dataset_id STRING;
    DECLARE description STRING;

    WHILE i < l DO
      SET dataset_id = SPLIT(paths[i], "/")[0] || "__US";
      EXECUTE IMMEDIATE
        "CREATE SCHEMA IF NOT EXISTS " || dataset_id;
      EXECUTE IMMEDIATE
        "LOAD DATA OVERWRITE TEMP TABLE information_schema_copy FROM FILES (format = 'PARQUET', uris = ['gs://podb/INFORMATION_SCHEMA/"
          || SPLIT(paths[i], "/")[0] || "/J_PODB/*.snappy.parquet'])";

      EXECUTE IMMEDIATE
        "SELECT COMMENT FROM information_schema_copy"
          || " WHERE TABLE_CATALOG = '"
          || SPLIT(paths[i], "/")[0]
          || "' AND TABLE_SCHEMA = '"
          || SPLIT(paths[i], "/")[1]
          || "' AND TABLE_NAME = '"
          || SPLIT(paths[i], "/")[2]
          || "'" INTO description;

      EXECUTE IMMEDIATE
        "ALTER TABLE IF EXISTS " || dataset_id || "." || SPLIT(paths[i], "/")[2]
        || " SET OPTIONS(description = '''" || description || "''')";

      EXECUTE IMMEDIATE
        "LOAD DATA OVERWRITE "
          || dataset_id || "." || SPLIT(paths[i], "/")[2]
          || " OPTIONS(description='''"
          || description
          || "''') FROM FILES (format = 'PARQUET', column_name_character_map = 'V2', uris = ['gs://podb/" || paths[i] || "/*.snappy.parquet'])";
      SET i = i + 1;
    END WHILE;
    EOT
  }
}
