variable "project" {
  description = "Project name"
  type        = string
  default     = "aws-data-lake"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_builds" {
  description = "Enable builds for Lambda functions"
  type        = bool
  default     = true
}
