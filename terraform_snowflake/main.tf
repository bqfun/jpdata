resource "snowflake_database" "main" {
  name = "mydb"
}

locals {
  bucket = "podb"
}

# リソース作成後に、Google Cloud 側の権限付与が必要
# DESCRIBE STORAGE INTEGRATION GCS_INT;
resource "snowflake_storage_integration" "main" {
  provider         = snowflake.ACCOUNT_ADMIN
  name             = "GCS_INT" # 大文字じゃないとリソースが迷子になる
  type             = "EXTERNAL_STAGE"
  storage_provider = "GCS"

  enabled = true

  storage_allowed_locations = ["gcs://${local.bucket}/"]
}

resource "snowflake_stage" "main" {
  provider            = snowflake.ACCOUNT_ADMIN
  name                = "my_ext_unload_stage"
  database            = snowflake_database.main.name
  schema              = "PUBLIC"
  url                 = "gcs://${local.bucket}"
  storage_integration = snowflake_storage_integration.main.name
}

locals {
  schemas = [
    {
      database = "PODB_JAPANESE_CALENDAR_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_CITY_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_CORPORATE_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_LAND_PRICE_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_MEDICAL_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_MESH_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_PREFECTURE_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_STATION_AND_RAILWAY_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_STREET_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    },
    {
      database = "PODB_JAPANESE_WEATHER_DATA"
      schema   = "J_PODB"
      schedule = "USING CRON 0 5 * * * Asia/Tokyo"
    }
  ]
}
module "main" {
  for_each       = { for index, s in local.schemas : s.database => s }
  source         = "./modules/common"
  schedule       = each.value.schedule
  podb_database  = each.value.database
  podb_schema    = each.value.schema
  stage_database = snowflake_stage.main.database
  stage_schema   = snowflake_stage.main.schema
  stage_name     = snowflake_stage.main.name
  task_database  = snowflake_database.main.name
  task_schema    = "PUBLIC"
  providers = {
    snowflake = snowflake.ACCOUNT_ADMIN
  }
}
