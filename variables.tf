variable "name_prefix" {
  description = "Prefix for naming/tagging network resources."
  type        = string
  default     = "pritunl"
}

variable "security_group_name" {
  description = <<-EOT
    Name of the security group. For a clean import of the existing group, set
    this to the EXACT current name (e.g. "launch-wizard-1"). Immutable: changing
    it forces SG recreation.
  EOT
  type        = string
  default     = "launch-wizard-1"
}

variable "security_group_description" {
  description = <<-EOT
    Description of the security group. For a clean import, set this to the EXACT
    current description string (capture it with describe-security-groups).
    Immutable: changing it forces SG recreation.
  EOT
  type        = string
  default     = "launch-wizard-1 created on import"
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH (port 22). Your home/Odido IP. Update when it rotates."
  type        = string
  default     = "193.142.200.248/32"
}

variable "enable_http_redirect" {
  description = "Open port 80 for the Pritunl HTTP->HTTPS console redirect."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to all network resources."
  type        = map(string)
  default     = {}
}
