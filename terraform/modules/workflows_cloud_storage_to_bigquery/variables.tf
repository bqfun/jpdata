variable "destination_dataset_id" {}
variable "destination_query" {}

variable "source_bucket_name" {}
variable "source_object_name" {}
variable "source_fields" {
  type = list(string)
}

variable "location" {}
variable "service_account_email" {}
