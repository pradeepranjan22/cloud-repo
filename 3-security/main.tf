locals {
  tags = merge(
    {
      "Module" = "landing-zone-3-security"
    },
    var.default_tags
  )
}

# --------------------------
# CloudTrail (Org-wide)
# --------------------------
resource "aws_cloudtrail" "org_trail" {
  name                          = "organization-trail"
  s3_bucket_name                = var.cloudtrail_s3_bucket_name
  kms_key_id                    = var.cloudtrail_kms_key_arn
  is_multi_region_trail         = true
  include_global_service_events = true
  is_organization_trail         = true

  tags = local.tags
}

# --------------------------
# GuardDuty
# --------------------------
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.security_tooling_account_id
}

resource "aws_guardduty_detector" "mgmt" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "this" {
  auto_enable = true
  detector_id = aws_guardduty_detector.mgmt.id
}

# --------------------------
# Security Hub
# --------------------------
resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = var.security_tooling_account_id
}

resource "aws_securityhub_account" "this" {
  depends_on = [aws_securityhub_organization_admin_account.this]
}

resource "aws_securityhub_organization_configuration" "this" {
  auto_enable = true
  depends_on  = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each   = toset(var.securityhub_standards)
  standards_arn = each.value
}

# --------------------------
# AWS Config (optional)
# --------------------------
resource "aws_config_configuration_aggregator" "this" {
  count = var.enable_aws_config ? 1 : 0

  name = "org-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = "arn:aws:iam::${var.log_archive_account_id}:role/service-role/config-role"
  }

  tags = local.tags
}