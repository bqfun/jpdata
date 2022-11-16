variable "google" {
  type = object({
    project = string
    number  = string
    region  = string
    zone    = string
  })
}
