# Output EC2 Instance ID
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

# Output CloudWatch Log Group Name
output "cloudwatch_log_group" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.ec2_log_group.name
}

# Output CloudWatch Log Stream Name
output "cloudwatch_log_stream" {
  description = "CloudWatch Log Stream Name"
  value       = aws_cloudwatch_log_stream.ec2_log_stream.name
}
