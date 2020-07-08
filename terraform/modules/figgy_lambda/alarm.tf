
# Triggers a SNS notification when this lambda exits with an error status.

resource "aws_cloudwatch_metric_alarm" "alarm" {

  alarm_name          = "${var.lambda_name}-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 60
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = 1
  unit                = "Count"
  alarm_actions       = [var.sns_alarm_topic]
  ok_actions          = [var.sns_alarm_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_name
  }

  tags = {
    lambda_name    = var.lambda_name
  }
}
