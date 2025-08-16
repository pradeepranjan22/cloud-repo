management_account_id = "123456789012"
email_domain          = "yourdomain.com"

ou_map = {
  Prod    = "ou-abc1-12345678"
  Dev     = "ou-abc1-23456789"
  Sandbox = "ou-abc1-34567890"
}

default_tags = {
  Project = "LandingZone"
  Owner   = "Platform"
}

account_definitions = [
  {
    account_name = "prod-app-1"
    email_prefix = "aws"
    ou           = "Prod"
    extra_tags   = { Environment = "prod" }
  },
  {
    account_name = "dev-app-1"
    email_prefix = "aws"
    ou           = "Dev"
    extra_tags   = { Environment = "dev" }
  }
]