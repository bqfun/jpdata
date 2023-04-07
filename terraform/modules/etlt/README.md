

# aa

```terraform
module "shukujitsu" {
  source = "../../modules/etlt"
  extract = {
    method = "GET"
    url    = "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"
  }
  pre_transform = [
    {
      call    = "convert"
      charset = "shift-jis"
    }
  ]
  transform = {
    bigquery_dataset_id     = "shukujitsu"
    bigquery_dataset_region = "US"
    fields = [
      "date",
      "name",
    ]
    sql = <<-EOF
    CREATE OR REPLACE TABLE holidays(
      date DATE PRIMARY KEY NOT ENFORCED NOT NULL OPTIONS(description="国民の祝日・休日月日"),
      name STRING NOT NULL OPTIONS(description="国民の祝日・休日名称"),
    )
    OPTIONS(
      description=${local.url},
      friendly_name="国民の祝日",
      labels=[
        ("freshness", "daily")
      ]
    )
    AS
    SELECT
      PARSE_DATE("%Y/%m/%d", date) AS date,
      name,
    FROM
      file
    QUALIFY
      IF(1013<=COUNT(*)OVER(), TRUE, ERROR("COUNT(*) < 1013"))
      AND IF(1=COUNT(*)OVER(PARTITION BY date), TRUE, ERROR("A duplicate date has been found"))
    ORDER BY
      date
    EOF
  }
}

module "daily" {
  source                      = "../../modules/scheduled_workflow"
  name                        = "daily"
  project_id                  = var.google.project
  region                      = var.google.region
  schedule                    = "0 9 * * *"
  time_zone                   = "Asia/Tokyo"
  workflow_service_account_id = module.simplte.invoker_id
  source_contents             = <<-EOF
  - shukujitsu:
      call: googleapis.workflowexecutions.v1.projects.locations.workflows.executions.create
      args:
        parent: ${module.shukujitsu.workflow_id}
EOF
}
```