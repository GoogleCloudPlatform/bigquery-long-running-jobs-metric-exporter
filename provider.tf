// Configure Google Provider
provider "google" {
}

// Specify Required Providers
terraform {
  required_providers {
    google = {
      version = "4.78.0"
    }
  }
}
