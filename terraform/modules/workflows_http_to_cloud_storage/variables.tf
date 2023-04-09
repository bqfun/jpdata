variable "simplte_url" {}
variable "simplte_name" {}

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

variable "loading" {
  type = object({
    location = string
  })
}

variable "service_account_email" {}
