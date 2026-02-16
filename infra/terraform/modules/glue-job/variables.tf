variable "job_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "bronze_bucket" {
  type = string
}

variable "silver_bucket" {
  type = string
}

variable "scripts_bucket" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
