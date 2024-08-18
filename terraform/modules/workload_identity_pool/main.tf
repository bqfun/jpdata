resource "google_project_service" "main" {
  service = "iamcredentials.googleapis.com"
}

resource "google_service_account" "terraform_plan" {
  account_id = "github-actions-terraform-plan"
}

resource "google_service_account" "terraform_apply" {
  account_id = "github-actions-terraform-apply"
}

resource "google_project_iam_member" "main" {
  project = google_service_account.terraform_plan.project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = toset([
    google_service_account.terraform_plan.email,
    google_service_account.terraform_apply.email,
  ])
  bucket = "jpdata-tfstate"
  role   = "roles/storage.admin"
  member = "serviceAccount:${each.key}"
}

resource "google_project_iam_member" "main" {
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

resource "google_service_account_iam_member" "main" {
  for_each = toset([
    google_service_account.terraform_plan.id,
    google_service_account.terraform_apply.id
  ])
  service_account_id = each.key
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/bqfun/jpdata"
}