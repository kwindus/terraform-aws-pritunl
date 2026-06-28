###############################################################################
# modules/network
#
# Manages the Pritunl security group, its rules, and the Elastic IP.
#
# NOTE ON IMPORTING AN EXISTING LAUNCH-WIZARD SG:
# An aws_security_group's `name` and `description` are immutable. If they do not
# match the real resource, Terraform plans a destroy+recreate (which would
# detach the SG from your running instance). So when importing the existing
# "launch-wizard-1" group, set var.security_group_name and
# var.security_group_description to the EXACT current values (see README for the
# describe-security-groups command to capture them).
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The box lives in the default VPC (172.31.0.0/16). Look it up rather than
# hardcoding the id, so this stays portable.
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "this" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = data.aws_vpc.default.id

  tags = merge(var.tags, {
    Name = var.security_group_name
  })

  # Name/description are immutable; guard against accidental recreation.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Ingress rules — one resource per rule so each maps 1:1 to an existing sgr-*
# id for clean imports.
# ---------------------------------------------------------------------------
locals {
  ingress_rules = {
    openvpn = {
      description = "udp1"
      from_port   = 1194
      to_port     = 1194
      ip_protocol = "udp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    wireguard = {
      description = "udp2"
      from_port   = 51820
      to_port     = 51820
      ip_protocol = "udp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      description = "https"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    ssh = {
      description = "homeip"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.ssh_cidr
    }
  }

  # Optional HTTP->HTTPS redirect rule for the admin console (port 80).
  # Not present on the current SG; enable to add it.
  http_redirect_rule = var.enable_http_redirect ? {
    http_redirect = {
      description = "http-redirect"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  } : {}

  all_ingress_rules = merge(local.ingress_rules, local.http_redirect_rule)
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.all_ingress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4

  tags = merge(var.tags, { Name = "${var.security_group_name}-${each.key}" })
}

# Default allow-all egress (matches the launch-wizard default).
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "allow-all-egress"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, { Name = "${var.security_group_name}-egress" })
}

# ---------------------------------------------------------------------------
# Elastic IP — imported. The association lives in the compute module so it sits
# next to the instance it points at.
# ---------------------------------------------------------------------------
resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-eip" })
}
