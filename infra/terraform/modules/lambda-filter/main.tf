resource "null_resource" "install_dependencies" {
  count = var.enable_build ? 1 : 0

  provisioner "local-exec" {
    command = "pip install -r ${abspath(path.module)}/../../../../python/lambda_filter/requirements.txt -t ${abspath(path.module)}/../../../../python/lambda_filter/package && cp ${abspath(path.module)}/../../../../python/lambda_filter/*.py ${abspath(path.module)}/../../../../python/lambda_filter/package/"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${abspath(path.module)}/../../../../python/lambda_filter/package"
  output_path = "${abspath(path.module)}/../../../../python/lambda_filter/lambda.zip"

  depends_on = [null_resource.install_dependencies]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.function_name}-permissions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = var.dynamodb_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = var.firehose_arn
      }
    ]
  })
}

resource "aws_lambda_function" "filter" {
  function_name    = var.function_name
  handler          = "filter_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      FIREHOSE_NAME = var.firehose_name
    }
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.filter.arn
  starting_position = "LATEST"
  batch_size        = 100
}
