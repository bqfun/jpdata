output "yaml" {
  value = <<-EOT
  - http_to_bigquery_${random_uuid.default.result}:
      steps:

        ${indent(8, module.http_to_cloud_storage.yaml)}

        ${indent(8, module.cloud_storage_to_bigquery.yaml)}
  EOT
}