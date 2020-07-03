resource "aws_cloudwatch_event_rule" "event_rule" {
  name = "${var.lambda_name}-cw-event"
  description = "This CW Event Triggers the Lambda: ${var.lambda_name}"
  event_pattern = var.cw_event_pattern
}

resource "aws_cloudwatch_event_target" "event_target" {
  target_id  = var.lambda_name
  arn        = var.lambda_arn
  rule       = aws_cloudwatch_event_rule.event_rule.name
}

resource "aws_lambda_permission" "lamda_permissions" {
  statement_id  = "CWInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}