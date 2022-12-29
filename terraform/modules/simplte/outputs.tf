output "url" {
  value       = google_cloud_run_service.simplte.status[0].url
}
