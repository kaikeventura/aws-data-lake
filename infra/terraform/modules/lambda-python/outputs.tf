output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.python_lambda.arn
}

output "lambda_invoke_arn" {
  description = "The Invoke ARN of the Lambda function (required for API Gateway)"
  value       = aws_lambda_function.python_lambda.invoke_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.python_lambda.function_name
}
