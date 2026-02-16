output "job_name" {
  value = aws_glue_job.silver.name
}

output "trigger_name" {
  value = aws_glue_trigger.daily.name
}
