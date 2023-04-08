output "source_contents" {
  value = <<-EOT
  - cloud_storage_to_bigquery_${random_uuid.default.result}:
      call: googleapis.bigquery.v2.jobs.insert
      args:
        projectId: ${data.google_project.project.project_id}
        body:
          configuration:
            query:
              defaultDataset:
                datasetId: ${var.destination_dataset_id}
                projectId: ${data.google_project.project.project_id}
              query: |-
                ${indent(14, var.destination_query)}
              tableDefinitions:
                file:
                  sourceUris:
                    - gs://${var.source_bucket_name}/${var.source_object_name}
                  schema:
                    fields:
                      %{ for item in var.source_fields ~}

                      - name: ${item}
                        type: STRING
                      %{ endfor }
                  sourceFormat: CSV
                  csvOptions:
                    skipLeadingRows: 1
              useLegacySql: false
  EOT
}

output "dataset_id" {
  value = var.destination_dataset_id
}
