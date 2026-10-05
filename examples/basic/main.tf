# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A public hosted zone for a domain. Route 53 answers queries for the domain once the
# domain's registrar lists the zone's name servers.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "domain_name" {
  description = "The domain name for the hosted zone, such as example.org"
  type        = string
}

module "route53_zone" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Zone"
    environment = "Development"
  }

  name = var.domain_name
}

output "zone_id" {
  description = "ID of the hosted zone, for creating records in it"
  value       = module.route53_zone.metadata.route53_zone.zone_id
}

output "name_servers" {
  description = "Name servers to give the domain's registrar"
  value       = module.route53_zone.metadata.route53_zone.name_servers
}
