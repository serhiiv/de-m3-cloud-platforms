terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create input bucket for PDFs
resource "google_storage_bucket" "pdf_input_bucket" {
  name                        = "${var.project_id}-pdf-input-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Create output bucket for JSON results
resource "google_storage_bucket" "json_output_bucket" {
  name                        = "${var.project_id}-json-output-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Create Cloud Function bucket and upload source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function"
  location = var.region
}

# Create ZIP file for the function
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function.zip"
  source_dir  = "${path.module}"
  excludes    = ["architecture.drawio", "main.tf", "variables.tf", "terraform.tfstate", "terraform.tfstate.backup", ".terraform"]
}

# Upload the Cloud Function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Enable required APIs
resource "google_project_service" "vision_api" {
  service                    = "vision.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudfunctions_api" {
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudbuild_api" {
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = true
}

# Wait for APIs to be enabled
resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    google_project_service.vision_api,
    google_project_service.cloudfunctions_api,
    google_project_service.cloudbuild_api
  ]

  create_duration = "30s"
}

# IAM role for the Cloud Function
resource "google_service_account" "function_account" {
  account_id   = "pdf-processor"
  display_name = "PDF Processor Service Account"
  depends_on   = [time_sleep.wait_30_seconds]
}

# Grant the service account permissions
resource "google_project_iam_member" "function_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_project_iam_member" "function_vision_admin" {
  project = var.project_id
  role    = "roles/visionai.admin"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

# Create Cloud Function
resource "google_cloudfunctions_function" "pdf_processor" {
  name        = "pdf-processor"
  description = "Process PDFs using Cloud Vision API"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
  
  entry_point = "process_pdf"
  
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.pdf_input_bucket.name
  }

  service_account_email = google_service_account.function_account.email

  environment_variables = {
    OUTPUT_BUCKET = google_storage_bucket.json_output_bucket.name
  }
}
