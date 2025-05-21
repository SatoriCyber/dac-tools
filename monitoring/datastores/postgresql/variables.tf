variable "aws_region" {
  default = "us-east-1"
}

variable "postgresql_dbname" {
}

variable "postgresql_user" {
}

variable "postgresql_password" {
}

variable "postgresql_satori_host" {
}

variable "postgresql_query" {
  default = "SELECT 1"
}

variable "postgresql_satori_port" {
  default = "5432"
}

variable "cron_interval" {
  description = "the trigger frequency of the lambda in minutes"
  default     = "60"
}