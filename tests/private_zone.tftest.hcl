# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details = { scope = "Test", purpose = "Private Zone", environment = "test" }
  name    = "internal.example.com"
}

# apply, because a VPC without a Region gets its Region from the provider after the plan.
run "private_zone" {
  command = apply
  variables {
    vpcs = [
      { id = "vpc-0123456789abcdef0" },
      { id = "vpc-0fedcba9876543210", region = "us-west-2" },
    ]
  }
  assert {
    condition = {
      for v in aws_route53_zone.this.vpc : v.vpc_id => v.vpc_region if v.vpc_id == "vpc-0fedcba9876543210"
    } == { "vpc-0fedcba9876543210" = "us-west-2" } && length(aws_route53_zone.this.vpc) == 2
    error_message = "Unexpected VPC associations."
  }
  assert {
    condition     = aws_route53_zone.this.comment == "Private hosted zone for internal.example.com"
    error_message = "Unexpected default comment for a private zone."
  }
}

# A VPC without a Region gets the module's region.
run "vpc_region_defaults_to_module_region" {
  command = plan
  variables {
    region = "eu-west-1"
    vpcs   = [{ id = "vpc-0123456789abcdef0" }]
  }
  assert {
    condition     = one(aws_route53_zone.this.vpc).vpc_region == "eu-west-1"
    error_message = "The VPC should be in the module's region."
  }
}

# Regression: the old module ignored every change to the VPC list after the zone was
# created. Adding and removing VPCs must now reach the plan, as an in-place update.
run "create_with_one_vpc" {
  variables {
    vpcs = [{ id = "vpc-0123456789abcdef0", region = "us-east-1" }]
  }
}

run "add_a_vpc" {
  variables {
    vpcs = [
      { id = "vpc-0123456789abcdef0", region = "us-east-1" },
      { id = "vpc-0fedcba9876543210", region = "us-east-1" },
    ]
  }
  assert {
    condition     = length(aws_route53_zone.this.vpc) == 2
    error_message = "The added VPC was not associated."
  }
}

run "remove_a_vpc" {
  variables {
    vpcs = [{ id = "vpc-0fedcba9876543210", region = "us-east-1" }]
  }
  assert {
    condition     = [for v in aws_route53_zone.this.vpc : v.vpc_id] == ["vpc-0fedcba9876543210"]
    error_message = "The removed VPC is still associated."
  }
}
