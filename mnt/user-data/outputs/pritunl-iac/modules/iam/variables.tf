variable "name_prefix" {
  description = "Prefix for naming IAM resources."
  type        = string
  default     = "pritunl"
}

variable "tags" {
  description = "Common tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
