variable "region" {
  description = "Region for account vending (usually the same as management account region)"
  type        = string
  default     = "ap-south-1"
}

variable "management_account_id" {
  description = "AWS Management (payer) account ID"
  type        = string
}

variable "email_domain" {
  description = "Domain used for generating account emails"
  type        = string
}

variable "ou_map" {
  description = "Map of OU names to OU IDs created in 1-control-tower"
  type        = map(string)
}

variable "default_tags" {
  description = "Default tags applied to all accounts"
  type        = map(string)
  default     = {}
}

variable "account_definitions" {
  description = "List of account definitions (name, email prefix, OU, tags)"
  type = list(object({
    account_name  = string
    email_prefix  = string
    ou            = string
    extra_tags    = map(string)
  }))
  default = []
}

variable "bootstrap_module_source" {
  description = "Path or registry for bootstrap module applied in each new account"
  type        = string
  default     = "../modules/account-bootstrap"
}