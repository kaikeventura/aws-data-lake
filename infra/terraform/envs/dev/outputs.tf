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

output "silver_bucket_name" {
  value = module.s3_silver.bucket_name
}

output "glue_job_name" {
  value = module.glue_job.job_name
}

output "silver_crawler_name" {
  value = module.glue_crawler_silver.crawler_name
}

output "silver_database_name" {
  value = module.glue_crawler_silver.database_name
}
