# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private hosted zone for two existing VPCs in different Regions, with most of the
# module's inputs. Route 53 answers queries for the zone only from inside those VPCs.

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
  region = "us-west-2"
}

variable "vpc_id" {
  description = "ID of a VPC in us-east-1, such as vpc-0123456789abcdef0. It needs DNS support and DNS hostnames turned on."
  type        = string
}

variable "second_vpc_id" {
  description = "ID of a VPC in us-west-2, the provider's Region. It needs DNS support and DNS hostnames turned on."
  type        = string
}

module "route53_zone" {
  source = "../../"

  # The module's Region. VPCs that do not set their own Region are in this one.
  region = "us-east-1"

  details = {
    scope            = "Example"
    scope_abbr       = "ex"
    purpose          = "Internal Services"
    purpose_abbr     = "svc"
    environment      = "Production"
    environment_abbr = "prd"
    additional_tags  = { CostCenter = "1234" }
  }

  name    = "internal.example.com"
  comment = "Private names for internal services"

  vpcs = [
    { id = var.vpc_id },
    { id = var.second_vpc_id, region = "us-west-2" },
  ]

  # Keep the zone if it still holds records, so a destroy cannot remove them.
  force_destroy = false
}

output "zone" {
  description = "ID, name and VPCs of the private hosted zone"
  value = {
    zone_id = module.route53_zone.metadata.route53_zone.zone_id
    name    = module.route53_zone.metadata.route53_zone.name
    vpcs    = module.route53_zone.metadata.route53_zone.vpc
  }
}
