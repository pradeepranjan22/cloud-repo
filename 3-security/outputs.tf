output "cloudtrail_arn" {
  description = "ARN of the org-wide CloudTrail"
  value       = aws_cloudtrail.org_trail.arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket name used for CloudTrail logs"
  value       = var.cloudtrail_s3_bucket_name
}

output "guardduty_admin_account_id" {
  description = "Delegated GuardDuty admin account ID"
  value       = aws_guardduty_organization_admin_account.this.admin_account_id
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector in Management Account"
  value       = aws_guardduty_detector.mgmt.id
}

output "securityhub_admin_account_id" {
  description = "Delegated Security Hub admin account ID"
  value       = aws_securityhub_organization_admin_account.this.admin_account_id
}

output "securityhub_standards_enabled" {
  description = "List of Security Hub standards ARNs enabled"
  value       = [for s in aws_securityhub_standards_subscription.this : s.standards_arn]
}

output "config_aggregator_name" {
  description = "AWS Config aggregator name"
  value       = try(aws_config_configuration_aggregator.this[0].name, null)
}