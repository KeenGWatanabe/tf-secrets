# variables.tf
variable "mongodb_username" {
  description = "MongoDB username (e.g., 'admin')"
  type        = string
  sensitive   = true  # Hides value in logs
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "mongodb_host" {
  description = "MongoDB host (e.g., 'cluster-xxxx.xxxx.docdb.amazonaws.com')"
  type        = string
}

variable "mongodb_database" {
  description = "Name of MongoDB to connect to"
  type = string
  sensitive = true
  
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}