variable "management_account_region" {
  description = "Region to manage AWS Organizations / Control Tower (must be a CT-supported region)."
  type        = string
}

variable "ou_list" {
  description = "List of top-level Organizational Units to create under the root."
  type        = list(string)
  default     = ["Sandbox", "Dev", "Test", "Prod", "Security", "SharedServices"]
}

variable "default_tags" {
  description = "Optional default tags to attach where supported."
  type        = map(string)
  default     = {}
}