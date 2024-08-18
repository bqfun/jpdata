variable "google" {
  type = object({
    project = string
    number  = string
    region  = string
    zone    = string
  })
}

variable "cloud_storage_service_account" {
  sensitive   = true
}
