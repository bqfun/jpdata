terraform {
  backend "gcs" {
    bucket = "jpdata-tfstate"
    prefix = "env/prod"
  }
}
