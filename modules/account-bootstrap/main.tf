locals {
  tags = merge({ CreatedBy = "account-bootstrap-module" }, var.default_tags)
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------
# VPC (optional baseline)
# -----------------------------------------------------
resource "aws_vpc" "baseline" {
  count             = var.create_vpc ? 1 : 0
  cidr_block        = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.tags, {
    Name = "baseline-vpc-${var.account_id}"
  })
}

resource "aws_internet_gateway" "baseline_igw" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.baseline[0].id
  tags   = merge(local.tags, { Name = "baseline-igw-${var.account_id}" })
}

# Public subnets
resource "aws_subnet" "public" {
  count = var.create_vpc ? length(var.public_subnet_suffixes) : 0
  vpc_id = aws_vpc.baseline[0].id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_suffixes[count.index])
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = merge(local.tags, { Name = "baseline-public-${count.index + 1}" })
}

# Private subnets
resource "aws_subnet" "private" {
  count = var.create_vpc ? length(var.private_subnet_suffixes) : 0
  vpc_id = aws_vpc.baseline[0].id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, var.private_subnet_suffixes[count.index])
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = merge(local.tags, { Name = "baseline-private-${count.index + 1}" })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route table for public subnets
resource "aws_route_table" "public" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.baseline[0].id
  tags   = merge(local.tags, { Name = "baseline-public-rt" })
}

resource "aws_route" "public_internet" {
  count = var.create_vpc ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.baseline_igw[0].id
}

resource "aws_route_table_association" "public_assoc" {
  count = var.create_vpc ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Optionally create VPC Flow Logs
resource "aws_cloudwatch_log_group" "flowlog" {
  count = var.create_vpc && var.enable_flow_logs ? 1 : 0
  name  = "/aws/vpc/flowlogs/${var.account_id}"
  retention_in_days = 30
  tags = local.tags
}

resource "aws_flow_log" "vpc_flow" {
  count = var.create_vpc && var.enable_flow_logs ? 1 : 0
  log_destination = aws_cloudwatch_log_group.flowlog[0].arn
  log_destination_type = "cloud-watch-logs"
  resource_type = "VPC"
  resource_id   = aws_vpc.baseline[0].id
  traffic_type  = "ALL"
  tags = local.tags
}

# -----------------------------------------------------
# Log bucket (optional)
# -----------------------------------------------------
resource "aws_s3_bucket" "log_bucket" {
  count = var.create_log_bucket ? 1 : 0

  bucket = var.log_bucket_name != "" ? var.log_bucket_name : "acct-${var.account_id}-logs-${random_id.bucket_id.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(local.tags, { Name = "account-log-bucket-${var.account_id}" })
}

resource "random_id" "bucket_id" {
  count = var.create_log_bucket && var.log_bucket_name == "" ? 1 : 0
  byte_length = 4
}

# -----------------------------------------------------
# Terraform admin role (optional) - role created inside the account so pipelines can assume it
# -----------------------------------------------------
resource "aws_iam_role" "tf_admin" {
  count = var.create_terraform_admin_role ? 1 : 0

  name = var.terraform_admin_role_name

  assume_role_policy = var.terraform_admin_trust_account != "" ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.terraform_admin_trust_account
        }
        Action = "sts:AssumeRole"
      }
    ]
  }) : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.tags, { Name = "tf-admin-role-${var.account_id}" })
}

# Attach useful policies to Terraform admin role
resource "aws_iam_role_policy_attachment" "tf_admin_attach" {
  count = var.create_terraform_admin_role ? 3 : 0

  role       = aws_iam_role.tf_admin[0].name
  policy_arn = element([
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ], count.index)
}

# -----------------------------------------------------
# Outputs for visibility
# -----------------------------------------------------