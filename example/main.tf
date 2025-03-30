terraform {
  required_version = "~> 1.11.0"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Module: Route53 - Zone
module "route53_zone" {
  source    = "../"
  providers = { aws.this = aws.us-east-1 }

  details = {
    scope       = "Demo"
    purpose     = "Route53 Zone - r53-example.com"
    environment = "dev"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  name          = "r53-example.com"
  comment       = null
  force_destroy = true

  # delegation_set_id = null
  # vpc = [
    # {
      # id     = "vpc-0123456789012345a"
      # region = "us-east-1"
    # },
    # {
      # id     = "vpc-0123456789012345b"
      # region = "us-west-2"
    # }
  # ]
}

output "metadata" {
  description = "Metadata"
  value       = module.route53_zone.metadata
}
