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

module "s3_silver" {
  source = "../../modules/s3-silver"

  bucket_suffix = random_id.bucket_suffix.hex
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
    Layer       = "silver"
  }
}

module "glue_job" {
  source = "../../modules/glue-job"

  job_name       = "silver-transform-job"
  database_name  = module.glue_crawler.database_name
  table_name     = "vendas_ingressos"
  bronze_bucket  = module.s3_bronze.bucket_name
  silver_bucket  = module.s3_silver.bucket_name
  scripts_bucket = module.s3_bronze.bucket_name
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "glue_crawler_silver" {
  source = "../../modules/glue-crawler"

  crawler_name    = "silver-vendas-crawler"
  database_name   = "silver_db"
  s3_target_path  = module.s3_silver.bucket_name
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "athena_view" {
  source = "../../modules/athena-view"

  view_name        = "vw_vendas_consolidadas_gold"
  database_name    = "spec_db"
  bronze_database  = module.glue_crawler.database_name
  silver_database  = module.glue_crawler_silver.database_name
}

module "s3_gold" {
  source = "../../modules/s3-gold"

  bucket_suffix = random_id.bucket_suffix.hex
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
    Layer       = "gold"
  }
}

module "glue_job_gold" {
  source = "../../modules/glue-job-gold"

  job_name        = "gold-transform-job"
  silver_database = module.glue_crawler_silver.database_name
  gold_database   = "gold_db"
  gold_bucket     = module.s3_gold.bucket_name
  silver_bucket   = module.s3_silver.bucket_name
  scripts_bucket  = module.s3_bronze.bucket_name
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }
}

module "glue_crawler_gold" {
  source = "../../modules/glue-crawler"

  crawler_name    = "gold-vendas-crawler"
  database_name   = module.glue_job_gold.database_name
  create_database = false
  s3_target_path  = module.s3_gold.bucket_name
  tags = {
    Environment = "dev"
    Project     = "aws-data-lake"
  }

  depends_on = [module.glue_job_gold]
}
