output "crawler_name" {
  value = aws_glue_crawler.bronze.name
}

output "database_name" {
  value = aws_glue_catalog_database.bronze.name
}
