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
    location    = string
  })
}

variable "service_account_email" {}
