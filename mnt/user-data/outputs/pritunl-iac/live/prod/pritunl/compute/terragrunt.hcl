###############################################################################
# live/prod/pritunl/compute/terragrunt.hcl
#
# Deploys the compute module (EC2 + EIP association). Depends on network (for
# the SG id and EIP allocation) and iam (for the instance profile). Imports the
# existing instance; the EIP association is also imported.
###############################################################################

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules/compute"
}

# --- Dependency wiring ------------------------------------------------------
dependency "network" {
  config_path = "../network"

  # Lets `plan`/`validate` run before network is applied.
  mock_outputs = {
    security_group_id = "sg-mock"
    eip_allocation_id = "eipalloc-mock"
    eip_public_ip     = "0.0.0.0"
    vpc_id            = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "iam" {
  config_path = "../iam"

  mock_outputs = {
    instance_profile_name = "pritunl-ssm-profile-mock"
    role_arn              = "arn:aws:iam::000000000000:role/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name_prefix       = "pritunl"
  instance_name     = "pritunl-vpn"
  ami_id            = "ami-0f8a61b66d1accaee"  # Ubuntu 24.04 noble x86
  instance_type     = "t3.small"
  availability_zone = "us-east-1c"
  key_name          = "pritunl"                # adjust if your key pair differs
  root_volume_size  = 20

  security_group_id     = dependency.network.outputs.security_group_id
  eip_allocation_id     = dependency.network.outputs.eip_allocation_id
  instance_profile_name = dependency.iam.outputs.instance_profile_name
}

# ---------------------------------------------------------------------------
# IMPORT BLOCKS. The instance id is known. The EIP association id has the form
# "<instance_id>/<allocation_id>".
# ---------------------------------------------------------------------------
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<EOF
import {
  to = aws_instance.this
  id = "i-02fb217a452a17b43"
}

import {
  to = aws_eip_association.this
  id = "i-02fb217a452a17b43/<EIP_ALLOCATION_ID>"
}
EOF
}
