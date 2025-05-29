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
  name                        = "${var.project_id}-pdf-input"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Create output bucket for JSON results
resource "google_storage_bucket" "json_output_bucket" {
  name                        = "${var.project_id}-json-output"
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
  source_dir  = "${path.module}/function"
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

resource "google_project_service" "run_api" {
  service                    = "run.googleapis.com"
  disable_dependent_services = true
}

# Wait for APIs to be enabled
resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    google_project_service.vision_api,
    google_project_service.cloudfunctions_api,
    google_project_service.cloudbuild_api,
    google_project_service.run_api
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

# Create bucket for invoice documents
resource "google_storage_bucket" "invoice_bucket" {
  name                        = "${var.project_id}-invoices"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Create bucket for company data
resource "google_storage_bucket" "company_bucket" {
  name                        = "${var.project_id}-company-data"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Create Cloud Function (Gen2)
resource "google_cloudfunctions2_function" "pdf_processor" {
  name        = "pdf-processor"
  location    = var.region
  description = "Process PDFs using Cloud Vision API"

  depends_on = [
    google_service_account.function_account,
    google_project_iam_member.function_storage_admin,
    google_project_iam_member.function_vision_admin,
    time_sleep.wait_30_seconds
  ]

  build_config {
    runtime     = "python39"
    entry_point = "process_pdf"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    service_account_email = google_service_account.function_account.email
    environment_variables = {
      OUTPUT_BUCKET = google_storage_bucket.json_output_bucket.name
      INVOICE_BUCKET = google_storage_bucket.invoice_bucket.name
      COMPANY_BUCKET = google_storage_bucket.company_bucket.name
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type    = "google.cloud.storage.object.v1.finalized"
    retry_policy  = "RETRY_POLICY_DO_NOT_RETRY"
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.pdf_input_bucket.name
    }
  }
}
