output "bronze_bucket_name" {
  value = module.s3_bronze.bucket_name
}

output "firehose_name" {
  value = module.kinesis_firehose.firehose_name
}

output "filter_lambda_name" {
  value = module.lambda_filter.function_name
}

output "dynamodb_stream_arn" {
  value = module.dynamodb.stream_arn
}

output "glue_crawler_name" {
  value = module.glue_crawler.crawler_name
}

output "glue_database_name" {
  value = module.glue_crawler.database_name
}
