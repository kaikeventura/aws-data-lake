resource "aws_dynamodb_table" "this" {
  name             = var.table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  range_key        = "SK"
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? "NEW_IMAGE" : null

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = var.tags
}
