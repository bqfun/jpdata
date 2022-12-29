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
}

resource "google_cloud_run_service" "simplte" {
  name     = "simplte"
  location = var.location

  template {
    spec {
      containers {
        image = "${var.repository_location}-docker.pkg.dev/${var.repository_project_id}/${var.repository_id}/simplte"
      }
    }
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_service.simplte.location
  project = google_cloud_run_service.simplte.project
  service = google_cloud_run_service.simplte.name
  role = "roles/run.invoker"
  member = "serviceAccount:${var.invoker_email}"
}