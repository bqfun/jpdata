variable "image" {}

variable "extraction" {
  type = object({
    url = string
  })
}

variable "tweaks" {
  type = list(object({
    call = string
    args = optional(map(any))
  }))
}

variable "transformation" {
  type = object({
    dataset_id_suffix = string
    fields            = list(string)
    query             = string
  })
}
