resource "google_project_service" "simplte" {
  for_each = toset([
    "cloudbuild.googleapis.com",
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
