resource "snowflake_task" "main" {
  name     = var.podb_database
  schema   = var.task_schema
  database = var.task_database

  schedule      = var.schedule
  sql_statement = <<-EOT
  DECLARE cursor CURSOR FOR
    SELECT table_catalog, table_schema, table_name FROM ${var.podb_database}.information_schema.tables WHERE table_schema = '${var.podb_schema}';

  BEGIN
    FOR record IN cursor DO
      EXECUTE IMMEDIATE '
        COPY INTO @"${var.stage_database}"."${var.stage_schema}"."${var.stage_name}"/' || record.table_catalog || '/' || record.table_schema || '/' || record.table_name || '/'
        || ' FROM ' || record.table_catalog || '.' || record.table_schema || '.' || record.table_name || '
        FILE_FORMAT = (TYPE = PARQUET)
        HEADER = TRUE
        OVERWRITE = TRUE;
      ';
    END FOR;
  END
  EOT

  user_task_managed_initial_warehouse_size = "XSMALL"
  enabled                                  = true
}
