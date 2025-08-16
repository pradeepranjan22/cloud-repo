###############################################################################
# Data sources
###############################################################################
data "aws_organizations_organization" "org" {
  provider = aws.management
}

# Root ID of the organization (there is exactly one root)
locals {
  root_id = data.aws_organizations_organization.org.roots[0].id
}

###############################################################################
# OU Creation (top-level under Root)
###############################################################################
resource "aws_organizations_organizational_unit" "ous" {
  provider  = aws.management
  for_each  = toset(var.ou_list)
  name      = each.key
  parent_id = local.root_id

  # Tagging OUs is supported; ignored if not permitted by the account
  tags = var.default_tags
}