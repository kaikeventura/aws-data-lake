resource "null_resource" "install_dependencies" {
  count = var.enable_build ? 1 : 0

  provisioner "local-exec" {
    command = "pip install -r ${abspath(path.module)}/../../../../python/requirements.txt -t ${abspath(path.module)}/../../../../python/package && cp ${abspath(path.module)}/../../../../python/*.py ${abspath(path.module)}/../../../../python/package/"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${abspath(path.module)}/../../../../python/package"
  output_path = "${abspath(path.module)}/../../../../python/lambda.zip"

  depends_on  = [null_resource.install_dependencies]
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "dynamodb-access-policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = var.table_arn
      }
    ]
  })
}

resource "aws_lambda_function" "python_lambda" {
  function_name    = "MyPythonLambda"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 15
  memory_size      = 128

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}
