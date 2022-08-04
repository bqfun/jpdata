variable "google" {
  type = object({
    project         = string
    region          = string
    zone            = string
  })
}
