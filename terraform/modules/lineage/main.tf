resource "google_project_service" "project" {
  project            = var.project_id
  service            = "datalineage.googleapis.com"
  disable_on_destroy = false
}
