output "source_contents" {
  value = <<-EOT
  - http_to_cloud_storage_${random_uuid.default.result}:
      call: googleapis.run.v1.namespaces.jobs.run
      args:
          name: namespaces/${data.google_project.project.name}/jobs/${google_cloud_run_v2_job.default.name}
          location: ${google_cloud_run_v2_job.default.location}
  EOT
}

output "bucket_name" {
  value = google_storage_bucket.default.name
}

output "object_name" {
  value = local.name
}
