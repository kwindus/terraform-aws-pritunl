###############################################################################
# modules/compute
#
# Manages the Pritunl EC2 instance and the EIP association.
#
# IMPORTING A RUNNING INSTANCE:
# A live instance has many attributes Terraform can't perfectly reconstruct from
# config (generated root volume ids, etc.). We pin the meaningful ones and use
# lifecycle.ignore_changes on the noisy/volatile ones to keep plans clean after
# import. In particular `ami` is ignored so a newer default AMI lookup never
# tries to replace the box out from under you.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default subnet in the chosen AZ — avoids hardcoding the subnet id.
data "aws_subnet" "selected" {
  availability_zone = var.availability_zone

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.selected.id
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  # Enforce IMDSv2 — good hygiene for a security box.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true

    tags = merge(var.tags, { Name = "${var.name_prefix}-root" })
  }

  tags = merge(var.tags, { Name = var.instance_name })

  lifecycle {
    ignore_changes = [
      ami,            # don't replace the box if the default AMI moves
      user_data,      # provisioning is Ansible's job, not cloud-init
    ]
  }
}

# Associate the imported Elastic IP with the instance.
resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = var.eip_allocation_id
}
