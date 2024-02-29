
data "google_project" "project" {
  project_id = var.project
}

data "google_compute_network" "vpc" {
  name = var.vpc
}

data "google_compute_subnetwork" "subnet" {
  name   = var.subnet
  region = var.region
}
