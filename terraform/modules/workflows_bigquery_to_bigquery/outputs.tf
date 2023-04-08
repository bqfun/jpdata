output "source_contents" {
  value = <<-EOT
  - bigquery_to_bigquery_${random_uuid.default.result}:
      call: googleapis.bigquerydatatransfer.v1.projects.locations.transferConfigs.startManualRuns
      args:
        parent: ${google_bigquery_data_transfer_config.default.name}
        body:
          requestedRunTime: $${time.format(sys.now() + 30)}
  EOT
}
