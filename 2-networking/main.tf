#########################################
# Transit Gateway
#########################################
resource "aws_ec2_transit_gateway" "this" {
  description = "Landing Zone Transit Gateway"
  tags        = merge(var.default_tags, { Name = "lz-tgw" })
}

#########################################
# Hub VPC
#########################################
resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.default_tags, { Name = "lz-hub-vpc" })
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id
  tags   = merge(var.default_tags, { Name = "lz-hub-igw" })
}

data "aws_availability_zones" "available" {}

# Hub Subnets
resource "aws_subnet" "hub_public" {
  count                   = 2
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.default_tags, {
    Name = "lz-hub-public-${count.index + 1}"
  })
}

resource "aws_subnet" "hub_private" {
  count             = 2
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.default_tags, {
    Name = "lz-hub-private-${count.index + 1}"
  })
}

#########################################
# NAT Gateway (Optional)
#########################################
resource "aws_eip" "nat" {
  count = var.enable_nat ? 2 : 0
  vpc   = true
  tags  = merge(var.default_tags, { Name = "lz-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "hub" {
  count         = var.enable_nat ? 2 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.hub_public[count.index].id
  tags          = merge(var.default_tags, { Name = "lz-nat-${count.index + 1}" })
}

#########################################
# Hub Route Tables
#########################################
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id
  tags   = merge(var.default_tags, { Name = "lz-hub-public-rt" })
}

resource "aws_route" "hub_public_inet" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub.id
}

resource "aws_route_table_association" "hub_public_assoc" {
  count          = length(aws_subnet.hub_public)
  subnet_id      = aws_subnet.hub_public[count.index].id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id
  tags   = merge(var.default_tags, { Name = "lz-hub-private-rt" })
}

resource "aws_route" "hub_private_nat" {
  count                  = var.enable_nat ? 2 : 0
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub[count.index].id
}

resource "aws_route_table_association" "hub_private_assoc" {
  count          = length(aws_subnet.hub_private)
  subnet_id      = aws_subnet.hub_private[count.index].id
  route_table_id = aws_route_table.hub_private.id
}

#########################################
# Spoke VPCs
#########################################
resource "aws_vpc" "spokes" {
  for_each             = var.spoke_vpc_cidrs
  cidr_block           = each.value
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.default_tags, {
    Name = "lz-${each.key}-vpc"
  })
}

resource "aws_internet_gateway" "spokes" {
  for_each = aws_vpc.spokes
  vpc_id   = each.value.id
  tags     = merge(var.default_tags, { Name = "lz-${each.key}-igw" })
}

# Spoke Subnets
resource "aws_subnet" "spoke_public" {
  for_each                = var.spoke_vpc_cidrs
  count                   = 2
  vpc_id                  = aws_vpc.spokes[each.key].id
  cidr_block              = cidrsubnet(each.value, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.default_tags, {
    Name = "lz-${each.key}-public-${count.index + 1}"
  })
}

resource "aws_subnet" "spoke_private" {
  for_each          = var.spoke_vpc_cidrs
  count             = 2
  vpc_id            = aws_vpc.spokes[each.key].id
  cidr_block        = cidrsubnet(each.value, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.default_tags, {
    Name = "lz-${each.key}-private-${count.index + 1}"
  })
}

#########################################
# Spoke Route Tables
#########################################
resource "aws_route_table" "spoke_public" {
  for_each = aws_vpc.spokes
  vpc_id   = each.value.id
  tags     = merge(var.default_tags, { Name = "lz-${each.key}-public-rt" })
}

resource "aws_route" "spoke_public_inet" {
  for_each                = aws_internet_gateway.spokes
  route_table_id          = aws_route_table.spoke_public[each.key].id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = each.value.id
}

resource "aws_route_table_association" "spoke_public_assoc" {
  for_each = aws_vpc.spokes
  count    = 2
  subnet_id      = aws_subnet.spoke_public[each.key][count.index].id
  route_table_id = aws_route_table.spoke_public[each.key].id
}

resource "aws_route_table" "spoke_private" {
  for_each = aws_vpc.spokes
  vpc_id   = each.value.id
  tags     = merge(var.default_tags, { Name = "lz-${each.key}-private-rt" })
}

resource "aws_route" "spoke_private_tgw" {
  for_each                = aws_vpc.spokes
  route_table_id          = aws_route_table.spoke_private[each.key].id
  destination_cidr_block  = "0.0.0.0/0"
  transit_gateway_id      = aws_ec2_transit_gateway.this.id
}

resource "aws_route_table_association" "spoke_private_assoc" {
  for_each = aws_vpc.spokes
  count    = 2
  subnet_id      = aws_subnet.spoke_private[each.key][count.index].id
  route_table_id = aws_route_table.spoke_private[each.key].id
}

#########################################
# TGW Attachments
#########################################
resource "aws_ec2_transit_gateway_vpc_attachment" "spokes" {
  for_each           = aws_vpc.spokes
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.id
  subnet_ids         = [for i in range(2) : aws_subnet.spoke_private[each.key][i].id]
  tags = merge(var.default_tags, {
    Name = "lz-${each.key}-tgw-attachment"
  })
}