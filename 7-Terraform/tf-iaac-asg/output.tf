output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.example.id
}

output "subnet_1_id" {
  description = "The first public subnet ID"
  value       = aws_subnet.example_1.id
}

output "subnet_2_id" {
  description = "The second public subnet ID"
  value       = aws_subnet.example_2.id
}

output "security_group_id" {
  description = "The Security Group ID"
  value       = aws_security_group.example.id
}

output "autoscaling_group_name" {
  description = "The Auto Scaling Group Name"
  value       = aws_autoscaling_group.example.name
}
