output "ou_ids" {
  description = "Map of OU names to their IDs."
  value       = { for k, v in aws_organizations_organizational_unit.ous : k => v.id }
}

output "root_id" {
  description = "AWS Organizations Root ID."
  value       = local.root_id
}