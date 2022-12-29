resource "google_project_service" "cloudscheduler" {
  project            = var.project_id
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloud_scheduler_job" "workflow" {
  name      = "base_registry_address"
  schedule  = var.schedule
  time_zone = "Asia/Tokyo"
  region    = var.region

  http_target {
    uri         = var.simplte_url
    http_method = "POST"
    body = base64encode(
      <<-EOT
      {
        "extraction": {
          "method": "GET",
          "url": "https://gov-csv-export-public.s3.ap-northeast-1.amazonaws.com/mt_town/mt_town_all.csv.zip"
        },
        "transformations": [
          {
            "call": "unzip"
          }
        ],
        "loading": {
          "bucket": "jpdata-source-eventarc",
          "object": "base_registry_address/mt_town_all.csv",
          "name": "mt_town_all.csv"
        }
      }
      EOT
    )
    oidc_token {
      service_account_email = var.simplte_invoker_email
    }
  }
}
