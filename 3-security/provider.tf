provider "aws" {
  region = var.region
}

# Optionally assume role into Security Tooling account
provider "aws" {
  alias  = "security_tooling"
  region = var.region

  assume_role {
    role_arn = var.assume_role_arn_security
  }
}

# Optionally assume role into Log Archive account
provider "aws" {
  alias  = "log_archive"
  region = var.region

  assume_role {
    role_arn = var.assume_role_arn_logarchive
  }
}