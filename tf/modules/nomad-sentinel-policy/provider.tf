terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = ">= 2.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "nomad" {
  address = var.nomad_address
}

provider "google" {
  project = var.project_id
  region  = var.region
}
