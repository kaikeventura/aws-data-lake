variable "crawler_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "create_database" {
  type    = bool
  default = true
}

variable "s3_target_path" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
