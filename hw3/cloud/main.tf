provider "google" {
  project = var.project
  region  = var.region
}


### Cloud SQL Instance
resource "google_sql_database_instance" "cloud_sql_instance" {
  name                = "de-m3-migration"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  settings {
    disk_autoresize = false
    disk_size       = 10
    disk_type       = "PD-SSD"
    edition         = "ENTERPRISE"
    tier            = "db-custom-1-3840"
    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_user" "cloud_postgres_user" {
  instance    = google_sql_database_instance.cloud_sql_instance.name
  name        = "postgres"
  password_wo = var.cloud_postgres_password

  depends_on = [google_sql_database_instance.cloud_sql_instance]
}


### Connection Profiles
resource "google_database_migration_service_connection_profile" "source_profile" {
  connection_profile_id = "pg-profile"
  location              = var.region

  postgresql {
    host     = var.docker_postgres_host
    port     = 5432
    username = var.docker_postgres_user
    password = var.docker_postgres_password
  }
}

resource "google_database_migration_service_connection_profile" "destination_profile" {
  connection_profile_id = "cloud-profile"
  location              = var.region

  postgresql {
    cloud_sql_id = google_sql_database_instance.cloud_sql_instance.name
  }
  depends_on = [google_sql_database_instance.cloud_sql_instance]
}

# ### Migration Job
resource "google_database_migration_service_migration_job" "migration_job" {
  migration_job_id = "pg-to-cloudsql"
  location         = var.region
  type             = "CONTINUOUS"
  static_ip_connectivity {}
  source      = google_database_migration_service_connection_profile.source_profile.name
  destination = google_database_migration_service_connection_profile.destination_profile.name

  depends_on = [
    google_sql_database_instance.cloud_sql_instance
  ]
}

# ### Запуск міграції

# resource "null_resource" "start_migration_job" {
#   provisioner "local-exec" {
#     command = <<EOT
#     gcloud datamigration migration-jobs start \
#       pg-to-cloudsql \
#       --region={var.region} \
#       --project={var.project} \
#       --quiet
#     EOT
#   }

#   depends_on = [
#     google_database_migration_service_migration_job.migration_job
#   ]
# }


# gcloud database-migration migration-jobs \
# demote-destination pg-to-cloudsql \
#   --region=europe-north1


# gcloud database-migration migration-jobs start pg-to-cloudsql --region=europe-north1 --project=de-module-3


# gcloud database-migration migration-jobs \
# promote pg-to-cloudsql \
#   --region=europe-north1
