# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_route53_zone" {
    defaults = {
      zone_id      = "Z0123456789ABCDEFGHIJ"
      arn          = "arn:aws:route53:::hostedzone/Z0123456789ABCDEFGHIJ"
      name_servers = ["ns-1.awsdns-01.com", "ns-2.awsdns-02.net", "ns-3.awsdns-03.org", "ns-4.awsdns-04.co.uk"]
    }
  }
}

variables {
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
  name    = "example.com"
}

# Only the required inputs: a public zone with no VPCs, no delegation set, and records
# protected from a destroy.
run "defaults" {
  command = plan

  assert {
    condition     = aws_route53_zone.this.name == "example.com"
    error_message = "Unexpected zone name."
  }
  assert {
    condition     = length(aws_route53_zone.this.vpc) == 0
    error_message = "The zone must be public by default."
  }
  assert {
    condition     = aws_route53_zone.this.delegation_set_id == null
    error_message = "No delegation set by default."
  }
  assert {
    condition     = aws_route53_zone.this.comment == "Public hosted zone for example.com"
    error_message = "Unexpected default comment."
  }
  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "force_destroy must be off by default."
  }
  assert {
    condition     = aws_route53_zone.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" })
    error_message = "Unexpected tags."
  }
}

run "defaults_apply" {
  command = apply

  assert {
    condition     = output.metadata.route53_zone.zone_id == "Z0123456789ABCDEFGHIJ" && length(output.metadata.route53_zone.name_servers) == 4
    error_message = "metadata.route53_zone is wrong."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws.region.abbr == "use1"
    error_message = "metadata.aws is wrong."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "defaults" && output.metadata.details.purpose.machine == "defaults"
    error_message = "metadata.details is wrong."
  }
}

run "options" {
  command = plan
  variables {
    comment           = "Public zone for example.com"
    delegation_set_id = "N0123456789ABCDEFGHIJ"
    force_destroy     = true
    details = {
      scope           = "Test"
      purpose         = "Web Site"
      environment     = "Production"
      additional_tags = { CostCenter = "1234" }
    }
  }
  assert {
    condition = alltrue([
      aws_route53_zone.this.comment == "Public zone for example.com",
      aws_route53_zone.this.delegation_set_id == "N0123456789ABCDEFGHIJ",
      aws_route53_zone.this.force_destroy == true,
      aws_route53_zone.this.tags["CostCenter"] == "1234",
    ])
    error_message = "An option did not reach the zone."
  }
}

# Regression: an empty abbreviation override used to produce an empty abbreviation.
run "empty_abbr_override_is_ignored" {
  command = plan
  variables {
    details = { scope = "Test", scope_abbr = "", purpose = "Web Site", purpose_abbr = "web", environment = "test" }
  }
  assert {
    condition     = output.metadata.details.scope.abbr == "test" && output.metadata.details.purpose.abbr == "web"
    error_message = "An empty override must fall back to the generated abbreviation."
  }
}
