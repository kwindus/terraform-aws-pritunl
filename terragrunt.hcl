###############################################################################
# live/terragrunt.hcl  (ROOT)
#
# Generates the AWS provider and the backend for every child config that
# `include`s this file. Starts with LOCAL state. When you're ready to move to
# S3 + DynamoDB (see ../bootstrap), comment out the local remote_state block
# and uncomment the S3 one, then run `terragrunt init -migrate-state` in each
# leaf.
###############################################################################

locals {
  region = "us-east-1"

  common_tags = {
    Project   = "pritunl-vpn"
    ManagedBy = "terragrunt"
    Owner     = "cat"
  }
}

# --- AWS provider (generated into each working dir) -------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

# --- LOCAL backend (current) ------------------------------------------------
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

# --- S3 + DynamoDB backend (LATER) ------------------------------------------
# Replace the remote_state block above with this once the bootstrap stack has
# created the bucket + lock table. Then `terragrunt init -migrate-state`.
#
# remote_state {
#   backend = "s3"
#
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#
#   config = {
#     bucket         = "pritunl-tfstate-<your-unique-suffix>"
#     key            = "${path_relative_to_include()}/terraform.tfstate"
#     region         = local.region
#     dynamodb_table = "pritunl-tfstate-locks"
#     encrypt        = true
#   }
# }

# Make common tags available to child inputs.
inputs = {
  tags = local.common_tags
}
