variable "image" {}

variable "extraction" {
  type = object({
    url = string
  })
}

variable "tweaks" {
  type = list(object({
    call = string
    args = map(any)
  }))
}

variable "loading" {
  type = object({
    location = string
  })
}

variable "transformation" {
  type = object({
    bigquery_dataset_id       = string
    bigquery_dataset_location = string
    fields                    = list(string)
    query                     = string
  })
}