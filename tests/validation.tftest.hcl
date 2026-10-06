# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}

variables {
  details = { scope = "Test", purpose = "Validation", environment = "test" }
  name    = "example.com"
}

run "scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

# Regression: name defaulted to "" and failed only inside the provider.
run "name_empty" {
  command = plan
  variables { name = "" }
  expect_failures = [var.name]
}

run "name_trailing_period" {
  command = plan
  variables { name = "example.com." }
  expect_failures = [var.name]
}

run "name_wildcard" {
  command = plan
  variables { name = "*.example.com" }
  expect_failures = [var.name]
}

run "name_label_too_long" {
  command = plan
  variables { name = "${join("", [for i in range(64) : "a"])}.example.com" }
  expect_failures = [var.name]
}

run "name_single_label_and_underscore_allowed" {
  command = plan
  variables { name = "_internal.corp" }
}

run "comment_too_long" {
  command = plan
  variables { comment = join("", [for i in range(257) : "a"]) }
  expect_failures = [var.comment]
}

# The provider would replace an empty comment with "Managed by Terraform".
run "comment_empty" {
  command = plan
  variables { comment = "" }
  expect_failures = [var.comment]
}

run "comment_default_is_cut_to_256_characters" {
  command = plan
  variables { name = "${join(".", [for i in range(4) : join("", [for j in range(60) : "a"])])}.com" }
  assert {
    condition     = length(aws_route53_zone.this.comment) == 256
    error_message = "The default comment must fit the 256-character limit."
  }
}

run "delegation_set_id_with_prefix" {
  command = plan
  variables { delegation_set_id = "/delegationset/N0123456789ABCDEFGHIJ" }
  expect_failures = [var.delegation_set_id]
}

# Regression: a delegation set with VPCs passed the module and failed in the provider.
run "delegation_set_id_with_vpcs" {
  command = plan
  variables {
    delegation_set_id = "N0123456789ABCDEFGHIJ"
    vpcs              = [{ id = "vpc-0123456789abcdef0" }]
  }
  expect_failures = [var.delegation_set_id]
}

run "vpc_id_invalid" {
  command = plan
  variables { vpcs = [{ id = "0123456789abcdef0" }] }
  expect_failures = [var.vpcs]
}

run "vpc_region_invalid" {
  command = plan
  variables { vpcs = [{ id = "vpc-0123456789abcdef0", region = "US East" }] }
  expect_failures = [var.vpcs]
}

# The provider keys VPCs by ID, so a duplicate would be dropped without a word.
run "vpc_listed_twice" {
  command = plan
  variables {
    vpcs = [
      { id = "vpc-0123456789abcdef0", region = "us-east-1" },
      { id = "vpc-0123456789abcdef0", region = "us-west-2" },
    ]
  }
  expect_failures = [var.vpcs]
}
