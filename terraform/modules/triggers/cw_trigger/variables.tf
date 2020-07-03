
variable "lambda_name" {
  description = "function_name as defined in the lambda that was created"
}

variable "lambda_arn" {
  description = "ARN of lambda to apply expression to"
}

variable "cw_event_pattern" {
  description = "CW Event pattern to match events off of. Should be json: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html"
}