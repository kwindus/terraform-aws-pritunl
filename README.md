# pritunl-iac

Terraform modules + Terragrunt config to manage the hand-built Pritunl VPN box
(EC2 + EIP + security group) and add an SSM instance profile. Ansible (added
separately) handles in-box configuration.

```
pritunl-iac/
├── bootstrap/              # S3 + DynamoDB remote-state backend (run once, later)
├── modules/
│   ├── network/            # security group + rules + Elastic IP
│   ├── iam/                # SSM role + instance profile (NEW)
│   └── compute/            # EC2 instance + EIP association
└── live/
    ├── terragrunt.hcl      # ROOT: provider + backend (local now, S3 later)
    └── prod/pritunl/
        ├── network/        # imports SG + rules + EIP
        ├── iam/            # creates SSM role/profile
        └── compute/        # imports instance, associates EIP
```

## Prerequisites

- Terraform >= 1.5 (import blocks), Terragrunt, AWS CLI configured for the
  account that owns the box (region us-east-1).
- The existing instance `i-02fb217a45xxxx` running.

---

## Step 1 — Capture the real resource IDs

The hand-built resources must be imported. Run these and note the values, then
paste them into the `<...>` placeholders in the leaf `terragrunt.hcl` files.

```bash
# Instance details: SG id, EIP allocation, subnet, key name, AMI
aws ec2 describe-instances --instance-ids i-02fb217xxxxxx \
  --query 'Reservations[0].Instances[0].[
    SecurityGroups[0].GroupId,
    KeyName,
    ImageId,
    SubnetId,
    Placement.AvailabilityZone]' --output text

# Security group exact name + description (immutable — must match in code)
SG_ID=<sg-from-above>
aws ec2 describe-security-groups --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].[GroupName,Description]' --output text

# The allow-all egress rule id (sgr-...)
aws ec2 describe-security-group-rules \
  --filters Name=group-id,Values="$SG_ID" \
  --query 'SecurityGroupRules[?IsEgress==`true`].SecurityGroupRuleId' --output text

# EIP allocation id (eipalloc-...) for the address on the instance
aws ec2 describe-addresses \
  --filters Name=instance-id,Values=i-02fb217a45xxxxx \
  --query 'Addresses[0].AllocationId' --output text
```

The four ingress rule ids are already filled in (captured from the console):
openvpn `sgr-096c72fxxxxxx`, wireguard `sgr-0ea5b0fecexxxx`,
https `sgr-07f64b39xxxxxx`, ssh `sgr-007ce2d5d94xxxxx`. Verify they still
match if you've edited rules since.

### Fill in the placeholders

- `live/prod/pritunl/network/terragrunt.hcl`
  - `security_group_description` → exact description string
  - `<SG_ID>`, `<EGRESS_RULE_ID>`, `<EIP_ALLOCATION_ID>`
- `live/prod/pritunl/compute/terragrunt.hcl`
  - `<EIP_ALLOCATION_ID>` (same value, in the association import id)
  - confirm `key_name`, `ami_id`, `availability_zone` match the capture output

---

## Step 2 — Import + apply, in dependency order

Terragrunt import blocks run during `apply`. Do the modules in order so outputs
exist for downstream dependencies.

```bash
cd live/prod/pritunl

# 1. Network — imports SG, rules, EIP
cd network
terragrunt init
terragrunt plan      # review: should show imports, NO destroy/recreate of the SG
terragrunt apply
cd ..

# 2. IAM — creates the SSM role/profile (greenfield)
cd iam
terragrunt apply
cd ..

# 3. Compute — imports instance, attaches SG/profile, associates EIP
cd compute
terragrunt init
terragrunt plan      # review carefully (see "Reading the plan" below)
terragrunt apply
cd ..
```

Or run the whole stack from `live/prod/pritunl` with `terragrunt run-all apply`
once you've reviewed each plan individually first.

### Reading the compute plan

After import, expect a few **in-place** changes (these are fine and intended):

- `iam_instance_profile` added → attaches SSM (this is the win).
- `metadata_options.http_tokens = required` → enables IMDSv2.
- `vpc_security_group_ids` set to the managed SG id.
- root volume `encrypted`/`gp3` may show drift if the live volume differs.

What you must NOT see: a plan to **destroy and recreate `aws_instance.this`**.
If you do, stop — usually it's an `ami`, `subnet_id`, or `key_name` mismatch.
`ami` is in `ignore_changes`, so the usual culprit is subnet/AZ or key name.
Fix the input to match reality and re-plan.

### After the first apply

The `generate "imports"` blocks are harmless to leave (import is a no-op once
state holds the resource)

---

## Step 3 (LATER) — Move state to S3 + DynamoDB

```bash
cd bootstrap
# edit variables.tf: set a globally-unique state_bucket_name
terraform init
terraform apply
terraform output         # note state_bucket + lock_table
```

Then in `live/terragrunt.hcl`: comment the `backend = "local"` remote_state
block, uncomment the S3 one, set the bucket/table names, and migrate each leaf:

```bash
cd live/prod/pritunl/network && terragrunt init -migrate-state
# repeat for iam, compute
```

---

## Day-2 operations

- **Odido IP rotated?** Change `ssh_cidr` in `network/terragrunt.hcl`,
  `terragrunt apply`. One line, done.
- **Add the console redirect port?** Set `enable_http_redirect = true`.
- **Rebuild from scratch?** Because state holds everything, `terragrunt destroy`
  then `apply` (minus the import blocks) reconstructs the infra; Ansible
  re-provisions the box.

## Notes / caveats

- The EIP is free while associated with a running instance; AWS bills a small
  hourly fee if it's allocated but unassociated (e.g. instance stopped long-term).
- This manages infra only. The Pritunl install, the `set-mongodb` fix, and
  service config are Ansible's job — see the `ansible/` setup (added next).
- `key_name` defaults to `pritunl`; confirm against the capture output — if your
  key pair has a different name the instance import will flag a mismatch.
