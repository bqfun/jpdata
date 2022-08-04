variable "project" {}
variable "dataset_id" {}
variable "description" {}
variable "schedule" {}
variable "source_contents" {}
variable "freshness_assertion" {
  type = object({
    schedule                    = string
    tables                      = string
    slack_webhook_url_secret_id = string
  })
}
