provider "aws" {
  region = var.aws_region
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name              = "/aws/ec2/logs"
  retention_in_days = 7
}

# Create CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  name           = "ec2-instance-log-stream"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}

# IAM Role for EC2 to push logs to CloudWatch
resource "aws_iam_role" "ec2_logging_role" {
  name = "EC2CloudWatchLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for CloudWatch logging
resource "aws_iam_policy" "cloudwatch_logging_policy" {
  name        = "EC2CloudWatchLoggingPolicy"
  description = "Allows EC2 to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.ec2_logging_role.name
  policy_arn = aws_iam_policy.cloudwatch_logging_policy.arn
}

# Instance Profile for EC2 logging
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2LoggingInstanceProfile"
  role = aws_iam_role.ec2_logging_role.name
}

# Launch an EC2 instance with logging enabled
resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y awslogs
              sudo systemctl enable awslogsd
              sudo systemctl start awslogsd
              echo "[general]
              state_file = /var/lib/awslogs/agent-state

              [messages]
              log_group_name = ${aws_cloudwatch_log_group.ec2_log_group.name}
              log_stream_name = ${aws_cloudwatch_log_stream.ec2_log_stream.name}
              file = /var/log/messages" > /etc/awslogs/awslogs.conf
              sudo systemctl restart awslogsd
              EOF

  tags = {
    Name = "EC2-CloudWatch-Logging"
  }
}

# CloudWatch Alarm for High Log Events
resource "aws_cloudwatch_metric_alarm" "high_log_events" {
  alarm_name          = "HighLogEvents"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IncomingLogEvents"
  namespace          = "AWS/Logs"
  period             = 60
  statistic          = "Sum"
  threshold          = 1000
  alarm_description  = "Trigger an alarm if log events exceed 1000 in a minute"
  alarm_actions      = [var.sns_topic_arn]
  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.ec2_log_group.name
  }
}
