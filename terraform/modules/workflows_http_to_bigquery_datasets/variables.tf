variable "simplte_name" {}
variable "simplte_url" {}
variable "dataset_id_suffix" {}

variable "etlt" {
  type = list(object({
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
  }))
}
