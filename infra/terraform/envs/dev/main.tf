module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name     = "TicketingSystem"
  stream_enabled = false
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "lambda_data_populator" {
  source = "../../modules/lambda-python"

  table_name   = module.dynamodb.table_name
  table_arn    = module.dynamodb.table_arn
  enable_build = true
}
