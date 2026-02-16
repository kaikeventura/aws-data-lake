variable "function_name" {
  type = string
}

variable "firehose_name" {
  type = string
}

variable "firehose_arn" {
  type = string
}

variable "dynamodb_stream_arn" {
  type = string
}

variable "enable_build" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
