data "aws_caller_identity" "current" {}


resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size        = var.message_batch_size
  event_source_arn  = var.dynamo_stream_arn
  enabled           = true
  function_name     = var.lambda_name
  starting_position = "LATEST"
}