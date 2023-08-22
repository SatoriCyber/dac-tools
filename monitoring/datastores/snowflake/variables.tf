variable "aws_region" {
  default = "us-east-1"
}

variable "snowflake_user" {
}

variable "snowflake_password" {
}

variable "snowflake_account" {
}

variable "snowflake_satori_host" {
}

variable "snowflake_warehouse" {
}

variable "snowflake_query" {
  default = "SELECT 1"
}

variable "cron_interval" {
  description = "the trigger frequency of the lambda in minutes"
  default = "60"
}