resource "google_project_service" "simplte" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_cloudbuild_trigger" "simplte" {
  name     = "dockerfiles-simplte"
  filename = "dockerfiles/simplte/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/simplte/**"]
  service_account = google_service_account.builder.id
}

resource "google_cloud_run_service" "simplte" {
  name     = "simplte"
  location = var.location

  template {
    spec {
      containers {
        image = "${var.repository_location}-docker.pkg.dev/${var.repository_project_id}/${var.repository_id}/simplte:latest"
        resources {
          limits = {
            # https://cloud.google.com/run/docs/configuring/cpu
            cpu = "1000m"
            # https://cloud.google.com/run/docs/configuring/memory-limits
            memory = "2048Mi"
          }
        }
      }
      container_concurrency = 1
    }
  }

  autogenerate_revision_name = true
}

resource "google_service_account" "builder" {
  account_id = "simplte-builder"
}

resource "google_cloud_run_service_iam_member" "builder" {
  location = google_cloud_run_service.simplte.location
  project = google_cloud_run_service.simplte.project
  service = google_cloud_run_service.simplte.name
  role = "roles/run.developer"
  member = "serviceAccount:${google_service_account.builder.email}"
}

resource "google_artifact_registry_repository_iam_member" "builder" {
  project    = var.repository_project_id
  location   = var.repository_location
  repository = var.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.builder.email}"
}

resource "google_project_iam_member" "builder" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.builder.email}"
}

resource "google_service_account" "invoker" {
  account_id = "simplte-invoker"
}

resource "google_cloud_run_service_iam_member" "invoker" {
  location = google_cloud_run_service.simplte.location
  project = google_cloud_run_service.simplte.project
  service = google_cloud_run_service.simplte.name
  role = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.invoker.email}"
}
