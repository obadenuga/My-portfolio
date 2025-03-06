# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# S3 Bucket for Static Website Hosting (Ensure Unique Name)
resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
}

# S3 Website Configuration
resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy (Ensure public access is allowed if required)
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# CloudWatch Log Group for EC2
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name = "/aws/ec2/web-server-logs"
}

# CloudWatch Log Stream for EC2
resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  name           = "web-server-log-stream"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}

# CloudWatch Metric Alarm for Log Monitoring
resource "aws_cloudwatch_metric_alarm" "high_log_events" {
  alarm_name          = "HighLogEventCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "LogEvents"
  namespace           = "AWS/Logs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Triggers when log event count exceeds 1000"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# SNS Topic for CloudWatch Alarm Notifications
resource "aws_sns_topic" "alarm_notifications" {
  name = "cloudwatch-alarms-topic"
}

# EC2 Instance with Security Group from Existing VPC
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "WebServer"
  }
}

# IAM Role for EC2 to send logs to CloudWatch
resource "aws_iam_role" "cloudwatch_role" {
  name = "EC2CloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatch Logs Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_attach" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
