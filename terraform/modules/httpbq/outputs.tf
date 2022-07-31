output "bucket_name" {
  value = google_storage_bucket.httpbq.name
}

output "dataset_id" {
  value = google_bigquery_dataset.httpbq.dataset_id
}
