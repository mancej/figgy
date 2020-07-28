locals {
  deploy_path = "functions/${var.lambda_name}.zip"
}

resource "aws_lambda_function" "figgy_lambda" {
  s3_bucket        = var.deploy_bucket
  s3_key           = local.deploy_path
  function_name    = var.lambda_name
  handler          = var.handler
  role             = aws_iam_role.figgy_role.arn
  runtime          = "python3.7"
  description      = var.description
  timeout          = var.lambda_timeout
  source_code_hash = var.sha256
  reserved_concurrent_executions = var.concurrent_executions
  depends_on       = [aws_iam_role.figgy_role, aws_s3_bucket_object.figgy_deploy]
  layers           = var.layers
  memory_size      = var.memory_size
}

resource "aws_s3_bucket_object" "figgy_deploy" {
  bucket = var.deploy_bucket
  key    = local.deploy_path
  source = var.zip_path
  etag = var.sha256
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.cw_lambda_log_retention
}