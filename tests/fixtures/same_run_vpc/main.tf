# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private zone for a VPC, and a public zone with a delegation set, each created in
# the same run as its dependency.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Only ever planned against a mocked provider, so it needs no flow logs.
#trivy:ignore:AWS-0178
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_route53_delegation_set" "this" {}

module "private" {
  source = "../../.."

  details = { scope = "Test", purpose = "Same Run Private", environment = "test" }
  name    = "internal.example.com"
  vpcs    = [{ id = aws_vpc.this.id }]
}

module "public" {
  source = "../../.."

  details           = { scope = "Test", purpose = "Same Run Public", environment = "test" }
  name              = "example.com"
  delegation_set_id = aws_route53_delegation_set.this.id
}
