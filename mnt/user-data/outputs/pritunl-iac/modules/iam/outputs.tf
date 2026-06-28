output "instance_profile_name" {
  description = "Name of the SSM instance profile to attach to the EC2 instance."
  value       = aws_iam_instance_profile.ssm.name
}

output "role_arn" {
  description = "ARN of the SSM role."
  value       = aws_iam_role.ssm.arn
}
