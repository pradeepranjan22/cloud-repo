output "vpc_id" {
  description = "Baseline VPC id created in the account (if enabled)"
  value       = try(aws_vpc.baseline[0].id, null)
}

output "public_subnet_ids" {
  description = "Public subnet ids for baseline VPC (if created)"
  value       = try(aws_subnet.public[*].id, [])
}

output "private_subnet_ids" {
  description = "Private subnet ids for baseline VPC (if created)"
  value       = try(aws_subnet.private[*].id, [])
}

output "log_bucket_name" {
  description = "Account-level log bucket name (if created)"
  value       = try(aws_s3_bucket.log_bucket[0].bucket, null)
}

output "terraform_admin_role_arn" {
  description = "ARN of the Terraform admin role created in the account (if enabled)"
  value       = try(aws_iam_role.tf_admin[0].arn, null)
}