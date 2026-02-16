output "job_name" {
  value = aws_glue_job.gold.name
}

output "database_name" {
  value = aws_glue_catalog_database.gold.name
}
