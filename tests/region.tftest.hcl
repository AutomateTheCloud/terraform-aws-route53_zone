# Copyright 2026 Automate the Cloud Inc.
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
  details = { scope = "Test", purpose = "Region", environment = "test" }
  name    = "example.com"
}

# No providers block anywhere in this file: the module uses the default aws provider.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

# Route 53 zones have no Region. region reaches the aws_region data source, and every
# VPC association that does not set its own.
run "region_reaches_every_resource" {
  command = apply
  variables {
    region = "eu-west-1"
    vpcs   = [{ id = "vpc-0123456789abcdef0" }]
  }
  assert {
    condition = alltrue([
      data.aws_region.this.region == "eu-west-1",
      one(aws_route53_zone.this.vpc).vpc_region == "eu-west-1",
      output.metadata.aws.region.name == "eu-west-1",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Regression: Regions missing from the old hard-coded table failed to plan.
run "region_not_in_old_table" {
  command = plan
  variables { region = "ca-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "caw1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
