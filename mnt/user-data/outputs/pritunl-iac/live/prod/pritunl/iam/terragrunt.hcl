###############################################################################
# live/prod/pritunl/iam/terragrunt.hcl
#
# Deploys the iam module (SSM role + instance profile). These are NEW resources
# — nothing to import. Applying this adds the Session Manager capability we
# want so the box no longer depends on inbound SSH.
###############################################################################

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules/iam"
}

inputs = {
  name_prefix = "pritunl"
}
