
variable "lambda_name" {
  description = "function_name as defined in the lambda that was created"
}

variable "dynamo_stream_arn" {
  description = "ARN of dynamo stream to trigger lambda invocations from"
}

variable "message_batch_size" {
  description = "Batch size to retrieve DDB updates as"
  default = 10
}