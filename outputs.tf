output "lambda" {
  value = aws_lambda_function.this
}

output "log_group" {
  value = aws_cloudwatch_log_group.this
}

output "role" {
  value = aws_iam_role.this
}
