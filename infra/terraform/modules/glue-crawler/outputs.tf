output "crawler_name" {
  value = aws_glue_crawler.bronze.name
}

output "database_name" {
  value = var.database_name
}
