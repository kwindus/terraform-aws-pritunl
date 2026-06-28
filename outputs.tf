output "security_group_id" {
  description = "ID of the Pritunl security group."
  value       = aws_security_group.this.id
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (for association in compute module)."
  value       = aws_eip.this.allocation_id
}

output "eip_public_ip" {
  description = "The Elastic IP address — your stable public address for the VPN."
  value       = aws_eip.this.public_ip
}

output "vpc_id" {
  description = "ID of the default VPC the SG lives in."
  value       = data.aws_vpc.default.id
}
