resource "google_project_service" "project" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "dataform.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "workflowexecutions.googleapis.com",
    "workflows.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "dataform" {
  account_id = "dataform"
}

resource "google_project_iam_member" "dataform" {
  for_each = toset(["roles/dataform.editor", "roles/logging.logWriter"])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.dataform.email}"
}

resource "google_workflows_workflow" "dataform" {
  name            = "dataform"
  region          = var.region
  service_account = google_service_account.dataform.id
  source_contents = templatefile("${path.module}/templates/source_contents.tftpl.yaml", {
    repository      = "projects/jpdata/locations/us-central1/repositories/jpdata-dataform",
    bucket          = var.bucket_name,
    bucket_eventarc = var.bucket_eventarc_name,
  })
}

resource "google_cloudbuild_trigger" "dataform" {
  name            = "dataform"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.dataform_workflow_invoker.id

  github {
    owner = "bqfun"
    name  = "jpdata-dataform"
    push {
      branch = "^main$"
    }
  }
}

resource "google_service_account" "dataform_workflow_invoker" {
  account_id = "dataform-workflow-invoker"
}

resource "google_project_iam_member" "eventarc" {
  for_each = toset([
    "roles/eventarc.eventReceiver",
    "roles/logging.logWriter",
    "roles/workflows.invoker",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dataform_workflow_invoker.email}"
}

resource "google_eventarc_trigger" "eventarc" {
  name     = "eventarc"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_eventarc_name
  }
  destination {
    workflow = google_workflows_workflow.dataform.id
  }
  service_account = google_service_account.dataform_workflow_invoker.email
  depends_on = [
    google_project_iam_member.eventarc,
    google_project_iam_member.eventarc_gs,
    google_project_iam_member.eventarc_pubsub,
  ]
}

// このトリガーでは、Cloud Storage 経由でイベントを受け取るために、
// サービス アカウント service-120299025068@gs-project-accounts.iam.gserviceaccount.com に
// ロール roles/pubsub.publisher が付与されている必要があります。
resource "google_project_iam_member" "eventarc_gs" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

// Cloud Pub/Sub で ID トークンを作成するには、
// このプロジェクトのサービス アカウント service-120299025068@gcp-sa-pubsub.iam.gserviceaccount.com に
// ロール roles/iam.serviceAccountTokenCreator が付与されている必要があります。
resource "google_project_iam_member" "eventarc_pubsub" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_secret_manager_secret" "github_personal_access_token" {
  secret_id = "github-personal-access-token"

  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
resource "google_secret_manager_secret_iam_member" "github_personal_access_token" {
  project   = google_secret_manager_secret.github_personal_access_token.project
  secret_id = google_secret_manager_secret.github_personal_access_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${var.project_number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "default" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataOwner",
    "roles/dataform.serviceAgent",
    "roles/storage.objectViewer",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_dataform_repository" "jpdata" {
  provider = google-beta
  project = var.project_id
  region = "us-central1"
  name = "jpdata-dataform"

  git_remote_settings {
    url = "https://github.com/bqfun/jpdata-dataform.git"
    default_branch = "main"
    authentication_token_secret_version = "${google_secret_manager_secret.github_personal_access_token.id}/versions/latest"
  }
}

// bqfunc の間借り実装

resource "google_workflows_workflow" "bqfunc" {
  name            = "bqfunc"
  region          = var.region
  service_account = google_service_account.dataform.id
  source_contents = templatefile("${path.module}/templates/bqfunc.tftpl.yaml", {
    repository      = "projects/jpdata/locations/us-central1/repositories/bqfunc",
  })
}

resource "google_cloudbuild_trigger" "bqfunc" {
  name            = "bqfunc"
  service_account = google_service_account.dataform_workflow_invoker.id

  github {
    owner = "bqfun"
    name  = "bqfunc"
    push {
      branch = "^master$"
    }
  }

  build {

    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["workflows", "run", "bqfunc", "--location", "asia-northeast1", "--data", "{\"location\": \"asia-northeast1\"}"]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["workflows", "run", "bqfunc", "--location", "asia-northeast1", "--data", "{\"location\": \"US\"}"]
    }

    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
  }
}

resource "google_dataform_repository" "bqfunc" {
  provider = google-beta
  project = var.project_id
  region = "us-central1"
  name = "bqfunc"

  git_remote_settings {
    url = "https://github.com/bqfun/bqfunc.git"
    default_branch = "main"
    authentication_token_secret_version = "${google_secret_manager_secret.github_personal_access_token.id}/versions/latest"
  }
}
