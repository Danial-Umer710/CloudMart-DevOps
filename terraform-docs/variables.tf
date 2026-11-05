variable "db_password" {
  description = "Master password for the RDS MySQL instance (set via TF_VAR_db_password)"
  type        = string
  sensitive   = true
}
