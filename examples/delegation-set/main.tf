# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Two public hosted zones that share one reusable delegation set, so both get the same
# four name servers. At a registrar, every domain can then use the same name servers.

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

variable "domain_names" {
  description = "Two or more domain names, one hosted zone each, such as [\"example.org\", \"example.net\"]"
  type        = list(string)
}

# A delegation set is a group of four name servers. Deleting it fails while any
# hosted zone still uses it.
resource "aws_route53_delegation_set" "this" {
  reference_name = "example-shared-name-servers"
}

module "route53_zone" {
  source   = "../../"
  for_each = toset(var.domain_names)

  details = {
    scope       = "Example"
    purpose     = "Shared Name Servers"
    environment = "Development"
  }

  name              = each.value
  delegation_set_id = aws_route53_delegation_set.this.id
}

output "name_servers" {
  description = "The four name servers every zone uses, to give each domain's registrar"
  value       = aws_route53_delegation_set.this.name_servers
}

output "zone_ids" {
  description = "ID of each hosted zone, by domain name"
  value       = { for name, zone in module.route53_zone : name => zone.metadata.route53_zone.zone_id }
}
