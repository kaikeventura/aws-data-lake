variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "stream_enabled" {
  description = "Enable or disable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
