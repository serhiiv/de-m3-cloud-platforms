terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}


locals {
  image = "${var.region}-docker.pkg.dev/${var.project}/${var.repo}/asp_web_app:latest"
}


provider "docker" {
  host = "unix:///var/run/docker.sock" # for local docker
  registry_auth {
    address = "${var.region}-docker.pkg.dev"
  }
}


resource "docker_image" "image" {
  name = local.image
  build {
    context = "."
  }
  triggers = {
    sha1_Dockerfile = filesha1("Dockerfile")
  }
}


resource "docker_registry_image" "registry" {
  name          = local.image
  keep_remotely = true
  depends_on    = [docker_image.image, google_artifact_registry_repository.my-repo]
}


provider "google" {
  project = var.project
  region  = var.region
}


resource "google_artifact_registry_repository" "my-repo" {
  location      = var.region
  project       = var.project
  repository_id = var.repo
  format        = "DOCKER"
}


resource "google_cloud_run_v2_service" "default" {
  name     = "cloudrun-asp-web-app"
  location = var.region
  project  = var.project
  deletion_protection = false

  template {
    containers {
      image = local.image
    }
  }
}


data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}


resource "google_cloud_run_v2_service_iam_policy" "policy" {
  project     = google_cloud_run_v2_service.default.project
  location    = google_cloud_run_v2_service.default.location
  name        = google_cloud_run_v2_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
