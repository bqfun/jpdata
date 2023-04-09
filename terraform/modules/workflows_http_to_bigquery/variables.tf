variable "simplte_name" {}
variable "simplte_url" {}
variable "service_account_email" {}
variable "dataset_id_suffix" {}

variable "etlt" {
  type = object({
    extraction = object({
      url = string
    })
    tweaks = list(object({
      call = string
      args = optional(map(any))
    }))
    transformation = object({
      fields            = list(string)
      query             = string
    })
  })
}
