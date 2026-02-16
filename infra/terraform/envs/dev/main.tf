module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name     = "TicketingSystem"
  stream_enabled = true
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

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "s3_bronze" {
  source = "../../modules/s3-bronze"

  bucket_suffix = random_id.bucket_suffix.hex
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
    Layer       = "bronze"
  }
}

module "kinesis_firehose" {
  source = "../../modules/kinesis-firehose"

  firehose_name = "show-tickets-bronze-stream"
  bucket_arn    = module.s3_bronze.bucket_arn
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "lambda_filter" {
  source = "../../modules/lambda-filter"

  function_name        = "lambda-sales-filter"
  firehose_name        = module.kinesis_firehose.firehose_name
  firehose_arn         = module.kinesis_firehose.firehose_arn
  dynamodb_stream_arn  = module.dynamodb.stream_arn
  enable_build         = true
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "glue_crawler" {
  source = "../../modules/glue-crawler"

  crawler_name    = "bronze-vendas-crawler"
  database_name   = "bronze_db"
  s3_target_path  = module.s3_bronze.bucket_name
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}
