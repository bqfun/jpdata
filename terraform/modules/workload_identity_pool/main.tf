resource "google_project_service" "main" {
  service = "iamcredentials.googleapis.com"
}

resource "google_service_account" "terraform_plan" {
  account_id = "github-actions-terraform-plan"
}

resource "google_project_iam_member" "terraform_plan" {
  project = google_service_account.terraform_plan.project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_storage_bucket_iam_member" "terraform_plan" {
  bucket = "jpdata-tfstate"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_service_account" "terraform_apply" {
  account_id = "github-actions-terraform-apply"
}

resource "google_storage_bucket_iam_member" "terraform_apply" {
  bucket = "jpdata-tfstate"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform_apply.email}"
}

resource "google_project_iam_member" "terraform_apply" {
  project = google_service_account.terraform_apply.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_apply.email}"
}

resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions"
  depends_on = [
    google_project_service.main
  ]
}

resource "google_iam_workload_identity_pool_provider" "main" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = "main"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "terraform_plan" {
  service_account_id = google_service_account.terraform_plan.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/bqfun/jpdata"
}

resource "google_service_account_iam_member" "terraform_apply" {
  service_account_id = google_service_account.terraform_apply.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/bqfun/jpdata"
}
