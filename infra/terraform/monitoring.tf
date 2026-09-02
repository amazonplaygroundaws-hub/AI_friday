resource "aws_sns_topic" "alerts" {
  name = "${var.name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "app_cpu" {
  alarm_name          = "${var.name}-${var.environment}-app-cpu-high"
  alarm_description   = "Average ASG CPU is over 80 percent for 10 minutes."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = var.alert_email == "" ? [] : [aws_sns_topic.alerts.arn]
}
