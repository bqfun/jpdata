locals {
  syukujitsu = {
    name = "holidays"
    extraction = {
      url = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
    }
    tweaks = [
      {
        call = "convert"
        args = {
          charset = "shift-jis"
        }
      }
    ]
    transformation = {
      query = <<-EOF
      CREATE OR REPLACE TABLE $${table}(
        date DATE PRIMARY KEY NOT ENFORCED NOT NULL OPTIONS(description="国民の祝日・休日月日"),
        name STRING NOT NULL OPTIONS(description="国民の祝日・休日名称"),
      )
      OPTIONS(
        description="https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv",
        friendly_name="国民の祝日",
        labels=[
          ("freshness", "daily")
        ]
      )
      AS
      SELECT
        PARSE_DATE("%Y/%m/%d", `国民の祝日_休日月日`) AS date,
        `国民の祝日_休日名称` AS name,
      FROM
        staging
      QUALIFY
        IF(1=COUNT(*)OVER(PARTITION BY date), TRUE, ERROR("A duplicate date has been found"))
      ORDER BY
        date
      EOF
    }
  }
}

module "main" {
  source         = "../../modules/workflows_http_to_bigquery_datasets"
  name           = "shukujitsu"
  tweakle_cpu    = "0.08"
  tweakle_memory = "128Mi"
  etlt           = [local.syukujitsu]
}
