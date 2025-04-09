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
  }
}

resource "google_sql_user" "cloud_postgres_user" {
  instance    = google_sql_database_instance.cloud_sql_instance.name
  name        = "postgres"
  password_wo = var.cloud_postgres_password

  depends_on = [google_sql_database_instance.cloud_sql_instance]
}

resource "google_sql_database" "target_db" {
  name     = "periodic_table"
  instance = google_sql_database_instance.cloud_sql_instance.name

  depends_on = [google_sql_database_instance.cloud_sql_instance]
}

### 3. Connection Profiles

resource "google_database_migration_service_connection_profile" "source_profile" {
  display_name          = "PostgreSQL Source"
  project               = var.project
  location              = var.region
  connection_profile_id = "pg-profile"

  postgresql {
    host     = var.docker_postgres_host
    port     = 5432
    username = var.docker_postgres_user
    password = var.docker_postgres_password
  }
}

resource "google_database_migration_service_connection_profile" "destination_profile" {
  project               = var.project
  location              = var.region
  display_name          = "CloudSQL Destination"
  connection_profile_id = "cloudsql-profile"

  cloudsql {
    cloud_sql_id = google_sql_database_instance.cloud_sql_instance.name
    # settings {
    #   source_id        = "projects/${var.project}/locations/${var.region}/connectionProfiles/${google_database_migration_service_connection_profile.source_profile.connection_profile_id}"
    #   database_version = "POSTGRES_15"
    #   tier             = "db-custom-1-3840" # Add the tier here
    # }
  }
}

# # ----------------------------
# # 4. Migration Job
# # ----------------------------

# resource "google_database_migration_service_migration_job" "migration_job" {
#   name       = "pg-to-cloudsql"
#   project    = "your-gcp-project"
#   region     = "us-central1"
#   type       = "ONE_TIME"
#   dump_path  = "gs://your-gcs-bucket/migration-dump/"

#   source {
#     connection_profile = google_database_migration_service_connection_profile.source_profile.name
#   }

#   destination {
#     connection_profile = google_database_migration_service_connection_profile.destination_profile.name
#   }

#   connectivity {
#     static_ip {}
#   }

#   depends_on = [
#     google_sql_database_instance.cloud_sql_instance,
#     google_sql_database.target_db
#   ]
# }

# # ----------------------------
# # 5. Автоматичний запуск міграції
# # ----------------------------

# resource "null_resource" "start_migration_job" {
#   provisioner "local-exec" {
#     command = <<EOT
#     gcloud datamigration migration-jobs start \
#       pg-to-cloudsql \
#       --region=us-central1 \
#       --project=your-gcp-project \
#       --quiet
#     EOT
#   }

#   depends_on = [
#     google_database_migration_service_migration_job.migration_job
#   ]
# }





# # provider "google" {
# #   project = var.project
# #   region  = var.region
# # }

# # terraform {
# #   required_providers {
# #     postgresql = {
# #       source  = "cyrilgdn/postgresql"
# #       version = "~> 1.25"
# #     }
# #   }
# # }


# # provider "postgresql" {
# #   host            = var.docker_postgres_host
# #   port            = 5432
# #   database        = "postgres"
# #   username        = var.docker_postgres_user
# #   password        = var.docker_postgres_password
# #   sslmode         = "disable"
# #   connect_timeout = 15
# # }

# # resource "postgresql_database" "periodic_database" {
# #   provider = "postgresql"
# #   name     = "docker-postgres-database"
# # }


# # resource "google_sql_database_instance" "postgresqldb" {
# #   name                = "cloud-postgres-database"
# #   database_version    = "POSTGRES_17"
# #   deletion_protection = false
# #   settings {
# #     disk_autoresize = false
# #     disk_size       = 10
# #     disk_type       = "PD-SSD"
# #     edition         = "ENTERPRISE"
# #     tier            = "db-custom-1-3840"
# #   }
# # }


# # resource "google_sql_ssl_cert" "sql_client_cert" {
# #   common_name = "cloud-database-cert"
# #   instance    = google_sql_database_instance.postgresqldb.name
# #   depends_on = [google_sql_database_instance.postgresqldb]
# # }


# # resource "google_sql_user" "sqldb_user" {
# #   instance    = google_sql_database_instance.postgresqldb.name
# #   name        = var.cloud_postgres_user
# #   password_wo = var.cloud_postgres_password
# #   depends_on  = [google_sql_ssl_cert.sql_client_cert]
# # }


# # # resource "google_database_migration_service_connection_profile" "postgresprofile" {
# # #   location              = var.region
# # #   connection_profile_id = "postgesql-profile"
# # #   display_name          = "de-m3-profileid"
# # #   postgresql {
# # #     cloud_sql_id = google_sql_database_instance.postgresqldb.name
# # #     host         = google_sql_database_instance.postgresqldb.public_ip_address
# # #     port         = 5432
# # #     username     = google_sql_user.sqldb_user.name
# # #     password     = google_sql_user.sqldb_user.password_wo
# # #     ssl {
# # #       client_key         = google_sql_ssl_cert.sql_client_cert.private_key
# # #       client_certificate = google_sql_ssl_cert.sql_client_cert.cert
# # #       ca_certificate     = google_sql_ssl_cert.sql_client_cert.server_ca_cert
# # #     }
# # #   }

# # #   depends_on = [google_sql_user.sqldb_user]
# # # }
