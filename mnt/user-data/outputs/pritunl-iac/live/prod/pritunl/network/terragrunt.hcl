###############################################################################
# live/prod/pritunl/network/terragrunt.hcl
#
# Deploys the network module (SG + rules + EIP) and imports the existing
# resources. Fill in the *_id placeholders below from the capture commands in
# the README before running.
###############################################################################

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules/network"
}

inputs = {
  name_prefix = "pritunl"

  # Set these to the EXACT current name/description of launch-wizard-1 so the
  # SG imports without recreation. Capture with:
  #   aws ec2 describe-security-groups --group-ids <SG_ID> \
  #     --query 'SecurityGroups[0].[GroupName,Description]' --output text
  security_group_name        = "launch-wizard-1"
  security_group_description = "REPLACE_WITH_EXACT_DESCRIPTION"

  ssh_cidr             = "193.142.200.248/32"  # your Odido IP; update on rotation
  enable_http_redirect = false                  # flip true to add port 80
}

# ---------------------------------------------------------------------------
# IMPORT BLOCKS — Terraform 1.5+. These run on the next `terragrunt apply`/
# `plan -generate-config-out` and pull existing resources into state. Replace
# every <...> with real ids (see README capture commands). After the first
# successful apply, you may delete this generate block.
# ---------------------------------------------------------------------------
generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = <<EOF
import {
  to = aws_security_group.this
  id = "<SG_ID>"            # e.g. sg-0abc123...
}

import {
  to = aws_vpc_security_group_ingress_rule.this["openvpn"]
  id = "sgr-096c72f0d93df3f6b"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["wireguard"]
  id = "sgr-0ea5b0fece653651e"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["https"]
  id = "sgr-07f64b393e3338136"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ssh"]
  id = "sgr-007ce2d5d94821470"
}

import {
  to = aws_vpc_security_group_egress_rule.all
  id = "<EGRESS_RULE_ID>"   # e.g. sgr-0deadbeef... (the allow-all egress rule)
}

import {
  to = aws_eip.this
  id = "<EIP_ALLOCATION_ID>"  # e.g. eipalloc-0abc123...
}
EOF
}
