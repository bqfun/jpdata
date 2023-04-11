variable "name" {}

variable "etlt" {
  type = list(object({
    name = string
    extraction = object({
      url    = string
      method = optional(string)
      body   = optional(map(any))
    })
    tweaks = list(object({
      call = string
      args = optional(map(any))
    }))
    transformation = object({
      fields = list(string)
      query  = string
    })
  }))
}

variable "tweakle_image" {
  type    = string
  default = "gcr.io/jpdata/github.com/bqfun/tweakle:f1b1611b08938817629e3863b2ccad87f86ab3f4"
}

variable "tweakle_cpu" {
  # https://cloud.google.com/run/docs/configuring/cpu
  type    = string
  default = "1000m"
}
variable "tweakle_memory" {
  # https://cloud.google.com/run/docs/configuring/memory-limits
  type    = string
  default = "2048Mi"
}

variable "labels" {
  description = "A map of labels to apply to contained resources."
  default     = null
  type        = map(string)
}
