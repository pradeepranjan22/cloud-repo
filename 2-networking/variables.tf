variable "region" {
  description = "AWS region where networking resources will be created."
  type        = string
}

variable "hub_vpc_cidr" {
  description = "CIDR block for the Hub (Shared Services) VPC."
  type        = string
}

variable "spoke_vpc_cidrs" {
  description = "Map of Spoke VPCs with their OU/account name as key and CIDR as value."
  type        = map(string)
}

variable "enable_nat" {
  description = "Whether to deploy NAT Gateways in Hub VPC."
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Tags applied to all networking resources."
  type        = map(string)
  default     = {}
}