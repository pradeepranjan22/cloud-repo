# Use credentials for the AWS Management (payer) account
provider "aws" {
  alias  = "management"
  region = var.management_account_region

  default_tags {
    tags = merge(
      {
        Project = "LandingZone"
        Module  = "control-tower"
      },
      var.default_tags
    )
  }
}