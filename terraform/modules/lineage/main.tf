resource "google_project_service" "lineage" {
  for_each = toset([
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_dataplex_lake" "primary" {
  project  = var.project_id
  location = var.location
  name     = "primary"
}

resource "google_dataplex_zone" "landing" {
  project  = var.project_id
  location = var.location
  name     = "landing"
  lake     = google_dataplex_lake.primary.name
  type     = "RAW"

  discovery_spec {
    enabled = false
  }

  resource_spec {
    location_type = "SINGLE_REGION"
  }
}

resource "google_dataplex_zone" "structured" {
  project  = var.project_id
  location = var.location
  name     = "structured"
  lake     = google_dataplex_lake.primary.name
  type     = "CURATED"

  discovery_spec {
    enabled = false
  }

  resource_spec {
    location_type = "SINGLE_REGION"
  }
}

resource "google_dataplex_asset" "primary" {
  for_each = toset([
    "base_registry_address",
    "gbizinfo",
    "houjinbangou",
    "shukujitsu",
  ])
  project       = var.project_id
  location      = var.location
  name          = replace(each.key, "_", "-")
  lake          = google_dataplex_lake.primary.name
  dataplex_zone = google_dataplex_zone.structured.name

  discovery_spec {
    enabled = false
  }

  resource_spec {
    name = "projects/${var.project_id}/datasets/${each.key}"
    type = "BIGQUERY_DATASET"
  }
}
