output "requested_account_ids" {
  description = "Map of account alias to requested account IDs"
  value       = { for k, v in aws_organizations_account.new_accounts : k => v.id }
}

output "account_emails" {
  description = "Generated account emails for traceability"
  value       = { for k, v in local.accounts : k => v.email }
}

output "bootstrap_outputs" {
  description = "Outputs from the bootstrap module for each account"
  value       = { for k, v in module.bootstrap : k => v }
}