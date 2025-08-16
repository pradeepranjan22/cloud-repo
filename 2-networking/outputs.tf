output "transit_gateway_id" {
  value       = aws_ec2_transit_gateway.this.id
  description = "Transit Gateway ID"
}

output "hub_vpc_id" {
  value       = aws_vpc.hub.id
  description = "Hub VPC ID"
}

output "spoke_vpc_ids" {
  value       = { for k, v in aws_vpc.spokes : k => v.id }
  description = "Map of Spoke VPC names to their IDs"
}

output "hub_public_subnet_ids" {
  value       = aws_subnet.hub_public[*].id
  description = "Hub Public Subnet IDs"
}

output "hub_private_subnet_ids" {
  value       = aws_subnet.hub_private[*].id
  description = "Hub Private Subnet IDs"
}

output "spoke_public_subnet_ids" {
  value       = { for k in var.spoke_vpc_cidrs : k => [for i in range(2) : aws_subnet.spoke_public[k][i].id] }
  description = "Map of Spoke VPCs to their Public Subnet IDs"
}

output "spoke_private_subnet_ids" {
  value       = { for k in var.spoke_vpc_cidrs : k => [for i in range(2) : aws_subnet.spoke_private[k][i].id] }
  description = "Map of Spoke VPCs to their Private Subnet IDs"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.hub[*].id
  description = "NAT Gateway IDs"
}