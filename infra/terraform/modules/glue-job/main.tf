resource "aws_s3_object" "glue_script" {
  bucket = var.scripts_bucket
  key    = "glue-scripts/silver_transform.py"
  source = "${path.module}/../../../../python/glue_job/silver_transform.py"
  etag   = filemd5("${path.module}/../../../../python/glue_job/silver_transform.py")
}

resource "aws_iam_role" "glue_job_role" {
  name = "${var.job_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_permissions" {
  name = "${var.job_name}-permissions"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bronze_bucket}/*",
          "arn:aws:s3:::${var.silver_bucket}/*",
          "arn:aws:s3:::${var.scripts_bucket}/*",
          "arn:aws:s3:::${var.bronze_bucket}",
          "arn:aws:s3:::${var.silver_bucket}",
          "arn:aws:s3:::${var.scripts_bucket}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:*",
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_glue_job" "silver" {
  name              = var.job_name
  role_arn          = aws_iam_role.glue_job_role.arn
  glue_version      = "4.0"
  max_capacity      = 0.0625
  timeout           = 10

  command {
    name            = "pythonshell"
    script_location = "s3://${var.scripts_bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3.9"
  }

  default_arguments = {
    "--job-language"  = "python"
    "--library-set"   = "analytics"
    "--database"      = var.database_name
    "--table"         = var.table_name
    "--output_path"   = "s3://${var.silver_bucket}/vendas_ingressos/"
    "--athena_output" = "s3://${var.bronze_bucket}/athena-results/"
  }

  tags = var.tags
}

resource "aws_glue_trigger" "daily" {
  name     = "${var.job_name}-daily-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 3 * * ? *)"

  actions {
    job_name = aws_glue_job.silver.name
  }
}
