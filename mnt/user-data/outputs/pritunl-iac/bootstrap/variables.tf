variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state. Add a unique suffix."
  type        = string
  default     = "pritunl-tfstate-CHANGE-ME"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locks."
  type        = string
  default     = "pritunl-tfstate-locks"
}

output "state_bucket" {
  description = "Name of the created state bucket — put this in live/terragrunt.hcl."
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "Name of the created lock table — put this in live/terragrunt.hcl."
  value       = aws_dynamodb_table.locks.name
}
