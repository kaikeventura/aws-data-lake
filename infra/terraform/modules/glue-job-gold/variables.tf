variable "job_name" {
  type = string
}

variable "silver_database" {
  type = string
}

variable "gold_database" {
  type = string
}

variable "gold_bucket" {
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
