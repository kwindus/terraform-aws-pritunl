###############################################################################
# modules/iam
#
# Creates an IAM role + instance profile granting the EC2 box AmazonSSM
# ManagedInstanceCore. This is what lets you reach the instance via Session
# Manager with NO inbound SSH — the fix for the Odido dynamic-IP problem.
#
# These resources are new (the hand-built instance had no profile), so there is
# nothing to import here. Attaching the profile to the existing instance is an
# in-place change handled by the compute module.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  name               = "${var.name_prefix}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm.name
  tags = var.tags
}
