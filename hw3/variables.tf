# for correct work create file 'terraform.tfvars' and add there your variables like:
# region = "your_region"

variable "project" {}
variable "region" {}

variable "docker_postgres_host" {}
variable "docker_postgres_user" { default = "postgres" }
variable "docker_postgres_password" {}

variable "cloud_postgres_user" { default = "postgres" }
variable "cloud_postgres_password" {}

