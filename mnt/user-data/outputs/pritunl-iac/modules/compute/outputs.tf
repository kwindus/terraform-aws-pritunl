output "instance_id" {
  description = "ID of the Pritunl EC2 instance."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the instance within the VPC."
  value       = aws_instance.this.private_ip
}

output "availability_zone" {
  description = "AZ the instance is running in."
  value       = aws_instance.this.availability_zone
}
