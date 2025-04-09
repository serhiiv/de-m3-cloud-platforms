provider "google" {
  project = var.project
  region  = var.region
}


resource "google_sql_database_instance" "postgresqldb" {
  name                = "cloud-database"
  database_version    = "POSTGRES_17"
  deletion_protection = false
  settings {
    disk_autoresize = false
    disk_size       = 10
    disk_type       = "PD-SSD"
    edition         = "ENTERPRISE"
    tier            = "db-custom-1-3840"
  }
}


resource "google_sql_ssl_cert" "sql_client_cert" {
  common_name = "cloud-database-cert"
  instance    = google_sql_database_instance.postgresqldb.name

  depends_on = [google_sql_database_instance.postgresqldb]
}


resource "google_sql_user" "sqldb_user" {
  instance    = google_sql_database_instance.postgresqldb.name
  name        = var.postgres_user
  password_wo = var.postgres_password
  depends_on  = [google_sql_ssl_cert.sql_client_cert]
}

# resource "google_database_migration_service_connection_profile" "postgresprofile" {
#   location              = var.region
#   connection_profile_id = "de-m3-profileid"
#   display_name          = "de-m3-profileid"
#   postgresql {
#     cloud_sql_id = google_sql_database_instance.postgresqldb.name
#     host         = google_sql_database_instance.postgresqldb.public_ip_address
#     port         = 5432
#     username     = google_sql_user.sqldb_user.name
#     password     = google_sql_user.sqldb_user.password_wo
#     ssl {
#       client_key         = google_sql_ssl_cert.sql_client_cert.private_key
#       client_certificate = google_sql_ssl_cert.sql_client_cert.cert
#       ca_certificate     = google_sql_ssl_cert.sql_client_cert.server_ca_cert
#     }
#   }

#   depends_on = [google_sql_user.sqldb_user]
# }
