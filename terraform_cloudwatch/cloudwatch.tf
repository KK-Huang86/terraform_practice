
# SNS Topic 用於接收告警通知
resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch-alerts"
}

# CloudWatch Alarm - CPU high
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5 分鐘
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "當 EC2 CPU 使用率超過 80% 時觸發警告"

  dimensions = {
    InstanceId = aws_instance.cloudwatch.id
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alerts.arn]
}

# CloudWatch Alarm - CPU low
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "ec2-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 6
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = " EC2 CPU 使用率低於 5% 超過 30 分鐘時觸發警告"

  dimensions = {
    InstanceId = aws_instance.cloudwatch.id
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
}

# CloudWatch Alarm - 狀態檢查失敗
resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "ec2-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 狀態檢查失敗"

  dimensions = {
    InstanceId = aws_instance.cloudwatch.id
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
}

# IAM Role 給 EC2 使用 CloudWatch Agent
resource "aws_iam_role" "cloudwatch_agent" {
  name = "cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 附加 CloudWatch Agent 政策
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# AWS Systems Manager，便於管理
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile，附加
resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = "cloudwatch-agent-profile"
  role = aws_iam_role.cloudwatch_agent.name
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "ec2_dashboard" {
  dashboard_name = "EC2-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [ # CPU使用情況
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.cloudwatch.id]
          ]
          period = 300
          stat   = "Average"
          region = "ap-northeast-1"
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = { 
          metrics = [ # 網路流量
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.cloudwatch.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.cloudwatch.id]
          ]
          period = 300
          stat   = "Average"
          region = "ap-northeast-1"
          title  = "EC2 Network Traffic"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [ #狀態
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.cloudwatch.id]
          ]
          period = 60
          stat   = "Maximum"
          region = "ap-northeast-1"
          title  = "EC2 Status Check"
        }
      }
    ]
  })
}
