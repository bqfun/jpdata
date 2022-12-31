resource "google_project_service" "lineage" {
  for_each = toset([
    "datalineage.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
