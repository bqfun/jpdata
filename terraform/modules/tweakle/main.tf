resource "google_cloudbuild_trigger" "workflow" {
  name     = "dockerfiles-tweakle"
  filename = "dockerfiles/tweakle/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/tweakle/**"]
}
