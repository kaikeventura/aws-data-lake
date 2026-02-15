variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "table_arn" {
  description = "The ARN of the DynamoDB table"
  type        = string
}

variable "enable_build" {
  description = "Enable or disable the build process."
  type        = bool
  default     = true
}
