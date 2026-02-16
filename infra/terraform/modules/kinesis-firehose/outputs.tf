output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.bronze.arn
}

output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.bronze.name
}
