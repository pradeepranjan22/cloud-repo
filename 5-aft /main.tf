locals {
  accounts = {
    for acct in var.account_definitions : acct.account_name => {
      email = "${acct.email_prefix}+${acct.account_name}@${var.email_domain}"
      ou_id = lookup(var.ou_map, acct.ou, null)
      tags  = merge(var.default_tags, acct.extra_tags)
    }
  }
}

# Example: Request account creation via Organizations API
resource "aws_organizations_account" "new_accounts" {
  for_each  = local.accounts

  name      = each.key
  email     = each.value.email
  role_name = "AWSAFTExecutionRole"   # IAM role provisioned in new account
  parent_id = each.value.ou_id
  tags      = each.value.tags
}

# Example bootstrap: attach baseline module to each account
module "bootstrap" {
  for_each = aws_organizations_account.new_accounts

  source = var.bootstrap_module_source

  providers = {
    aws = aws
  }

  account_id   = each.value.id
  account_name = each.key
  tags         = var.default_tags
}