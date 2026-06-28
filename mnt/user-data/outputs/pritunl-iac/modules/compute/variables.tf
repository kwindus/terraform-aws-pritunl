variable "name_prefix" {
  description = "Prefix for naming compute resources."
  type        = string
  default     = "pritunl"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
  default     = "pritunl-vpn"
}

variable "ami_id" {
  description = "AMI id the instance was launched from (Ubuntu 24.04 noble x86). Ignored after import via lifecycle, but must match for the initial import."
  type        = string
  default     = "ami-0f8a61b66d1accaee"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "availability_zone" {
  description = "AZ the instance runs in (selects the default subnet)."
  type        = string
  default     = "us-east-1c"
}

variable "key_name" {
  description = "Name of the EC2 key pair (the .pem you SSH with). Likely 'pritunl'."
  type        = string
  default     = "pritunl"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 20
}

variable "security_group_id" {
  description = "Security group id to attach (from the network module)."
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for SSM (from the iam module)."
  type        = string
}

variable "eip_allocation_id" {
  description = "Allocation id of the Elastic IP to associate (from the network module)."
  type        = string
}

variable "tags" {
  description = "Common tags applied to compute resources."
  type        = map(string)
  default     = {}
}
