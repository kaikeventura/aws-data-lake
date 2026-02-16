resource "aws_glue_catalog_database" "bronze" {
  count = var.create_database ? 1 : 0
  name  = var.database_name
}

resource "aws_iam_role" "glue_role" {
  name = "${var.crawler_name}-role"

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
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  name = "${var.crawler_name}-s3-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_target_path}",
        "arn:aws:s3:::${var.s3_target_path}/*"
      ]
    }]
  })
}

resource "aws_glue_crawler" "bronze" {
  name          = var.crawler_name
  role          = aws_iam_role.glue_role.arn
  database_name = var.create_database ? aws_glue_catalog_database.bronze[0].name : var.database_name
  schedule      = "cron(0 2 * * ? *)"

  s3_target {
    path = "s3://${var.s3_target_path}/vendas_ingressos/"
  }

  tags = var.tags
}
