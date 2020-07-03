resource "aws_cloudwatch_event_rule" "cron_rate" {
  name                = "${var.lambda_name}-cron-schedule"
  description         = "Cron schedule for ${var.lambda_name}"
  schedule_expression = var.schedule_expression
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "cron_target" {
  target_id  = "${var.lambda_name}-cron-target"
  arn        = var.lambda_arn
  rule       = aws_cloudwatch_event_rule.cron_rate.name
}

resource "aws_lambda_permission" "cron_trigger_permission" {
  statement_id  = "AllowCronTrigger"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_rate.arn
}