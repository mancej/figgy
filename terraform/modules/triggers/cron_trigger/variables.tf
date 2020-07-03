
variable "lambda_name" {
  description = "function_name as defined in the lambda that was created"
}

variable "schedule_expression" {
  description = "cron expression that matches valid cloudwatch cron expressions for execution"
}

variable "lambda_arn" {
  description = "ARN of lambda to apply expression to"
}