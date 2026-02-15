variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type = string
}

variable "project" {
  type = string
  default = "aws-data-lake"
}

variable "env" {
  type = string
  default = "dev"
}
