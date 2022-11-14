resource "google_secret_manager_secret" "github_personal_access_token" {
  secret_id = "github-personal-access-token"

  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_iam_member" "github_personal_access_token" {
  project = google_secret_manager_secret.github_personal_access_token.project
  secret_id = google_secret_manager_secret.github_personal_access_token.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_secret_manager_secret" "houjinbangou_webapi_id" {
  secret_id = "houjinbangou-webapi-id"

  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_iam_member" "houjinbangou_webapi_id" {
  project = google_secret_manager_secret.houjinbangou_webapi_id.project
  secret_id = google_secret_manager_secret.houjinbangou_webapi_id.secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${var.google.number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket" "source" {
  name     = "${var.google.project}-source"
  location = var.google.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "source_houjinbangou_change_history" {
  name     = "${var.google.project}-source-houjinbangou-change-history"
  location = var.google.region
  uniform_bucket_level_access = true
}

resource "google_service_account" "httpgcs" {
  account_id   = "httpgcs"
}

resource "google_project_iam_member" "httpgcs" {
  for_each = toset([
    "roles/batch.jobsEditor",
    "roles/eventarc.eventReceiver",
    "roles/iam.serviceAccountUser",
    "roles/workflows.invoker",
  ])
  project  = var.google.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.httpgcs.email}"
}

module "gbizinfo" {
  source = "../../modules/httpgcs"
  name = "gbizinfo"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 9 * * *"
  region = var.google.region
  source_contents = templatefile("source_contents/gbizinfo.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
  })
}

module "shukujitsu" {
  source = "../../modules/httpgcs"
  name = "shukujitsu"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 6 * * *"
  region = var.google.region
  source_contents = templatefile("source_contents/shukujitsu.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
  })
}

module "houjinbangou" {
  source = "../../modules/httpgcs"
  name = "houjinbangou"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 0 1 * *"
  region = var.google.region
  source_contents = templatefile("source_contents/houjinbangou_latest.tftpl.yaml", {
    bucket = google_storage_bucket.source.name
    repositoryId = google_artifact_registry_repository.source.repository_id
    location = google_artifact_registry_repository.source.location
  })
}

module "houjinbangou_change_history" {
  source = "../../modules/httpgcs"
  name = "houjinbangou_change_history"
  service_account_id = google_service_account.httpgcs.id
  service_account_email = google_service_account.httpgcs.email
  schedule = "0 0 * * *"
  region = var.google.region
  source_contents = templatefile("source_contents/houjinbangou_change_history.tftpl.yaml", {
    bucket = google_storage_bucket.source_houjinbangou_change_history.name
    repositoryId = google_artifact_registry_repository.source.repository_id
    location = google_artifact_registry_repository.source.location
    secretName = "${google_secret_manager_secret.houjinbangou_webapi_id.name}/versions/latest"
    workflowId = module.dataform.workflow_id
  })
}

resource "google_project_iam_member" "dataform" {
  for_each = toset([
    "roles/dataform.serviceAgent",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataOwner",
    "roles/bigquery.connectionAdmin",
  ])
  project = var.google.project
  role    = each.key
  member  = "serviceAccount:service-${var.google.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

module "dataform" {
  source = "../../modules/dataform"
  project = var.google.project
  region = var.google.region
  connection_id = "${google_bigquery_connection.main.project}.${google_bigquery_connection.main.location}.${google_bigquery_connection.main.connection_id}"
  bucket_source = google_storage_bucket.source.name
}

resource "google_bigquery_connection" "main" {
  connection_id = "main"
  project = var.google.project
  location = var.google.region
  cloud_resource {}
}

resource "google_project_iam_member" "mainConnectionPermissionGrant" {
  project = var.google.project
  role = "roles/storage.objectViewer"
  member = format("serviceAccount:%s", google_bigquery_connection.main.cloud_resource[0].service_account_id)
}

resource "google_project_iam_member" "cloud_batch_upload_objects_to_cloud_storage" {
  project = var.google.project
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.google.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "source" {
  location      = var.google.region
  repository_id = "source"
  format        = "DOCKER"
}

resource "google_cloudbuild_trigger" "dockerfiles_houjinbangou_latest" {
  name     = "dockerfiles-houjinbangou-latest"
  filename = "dockerfiles/houjinbangou_latest/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/houjinbangou_latest/**"]
}

resource "google_cloudbuild_trigger" "dockerfiles_houjinbangou_change_history" {
  name     = "dockerfiles-houjinbangou-change-history"
  filename = "dockerfiles/houjinbangou_change_history/cloudbuild.yaml"

  github {
    owner = "bqfun"
    name  = "jpdata"
    push {
      branch = "^main$"
    }
  }
  included_files = ["dockerfiles/houjinbangou_change_history/**"]
}

resource "google_eventarc_trigger" "httpgcs" {
  name     = "httpgcs"
  location = var.google.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.source.name
  }
  destination {
    workflow = module.dataform.workflow_id
  }
  service_account = google_service_account.httpgcs.email
  depends_on = [
    google_project_iam_member.httpgcs,
    google_project_iam_member.httpgcs_eventarc_gs,
    google_project_iam_member.httpgcs_eventarc_pubsub,
  ]
}

// このトリガーでは、Cloud Storage 経由でイベントを受け取るために、
// サービス アカウント service-120299025068@gs-project-accounts.iam.gserviceaccount.com に
// ロール roles/pubsub.publisher が付与されている必要があります。
resource "google_project_iam_member" "httpgcs_eventarc_gs" {
  project  = var.google.project
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:service-${var.google.number}@gs-project-accounts.iam.gserviceaccount.com"
}

// Cloud Pub/Sub で ID トークンを作成するには、
// このプロジェクトのサービス アカウント service-120299025068@gcp-sa-pubsub.iam.gserviceaccount.com に
// ロール roles/iam.serviceAccountTokenCreator が付与されている必要があります。
resource "google_project_iam_member" "httpgcs_eventarc_pubsub" {
  project  = var.google.project
  role     = "roles/iam.serviceAccountTokenCreator"
  member   = "serviceAccount:service-${var.google.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
