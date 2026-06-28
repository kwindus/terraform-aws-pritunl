###############################################################################
# bootstrap/main.tf
#
# Creates the S3 bucket + DynamoDB lock table for Terraform remote state.
# This stack itself uses LOCAL state (chicken-and-egg: it builds the backend
# that everything else will use). Run it once, then point live/terragrunt.hcl
# at the bucket and migrate.
###############################################################################

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Local state on purpose — keep bootstrap/terraform.tfstate in the repo-adjacent
  # dir (gitignored) or a safe place. It's tiny and rarely changes.
}

provider "aws" {
  region = var.region
}

# Bucket names are globally unique — add your own suffix.
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  tags = {
    Project   = "pritunl-vpn"
    Purpose   = "terraform-remote-state"
    ManagedBy = "terraform-bootstrap"
  }
}

# Versioning lets you recover a corrupted/overwritten state file.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Never expose state publicly.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking (PAY_PER_REQUEST = no idle cost; free-tier
# friendly at this volume).
resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "pritunl-vpn"
    Purpose   = "terraform-state-locks"
    ManagedBy = "terraform-bootstrap"
  }
}
