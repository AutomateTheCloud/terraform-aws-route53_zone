# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the module's Region.
    - `route53_zone` - The hosted zone: its `zone_id` (use this for records), `arn`, `name`, `name_servers` (give these to the domain's registrar to make a public zone answer for the domain), `primary_name_server`, `comment`, `delegation_set_id`, `force_destroy`, `vpc` (the associated VPCs, each with its `vpc_id` and `vpc_region`), `tags` and `tags_all`.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    route53_zone = local.output_resources.route53_zone
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    route53_zone = {
      arn                 = aws_route53_zone.this.arn
      comment             = aws_route53_zone.this.comment
      delegation_set_id   = aws_route53_zone.this.delegation_set_id
      force_destroy       = aws_route53_zone.this.force_destroy
      id                  = aws_route53_zone.this.id
      name                = aws_route53_zone.this.name
      name_servers        = aws_route53_zone.this.name_servers
      primary_name_server = aws_route53_zone.this.primary_name_server
      tags                = aws_route53_zone.this.tags
      tags_all            = aws_route53_zone.this.tags_all
      vpc                 = aws_route53_zone.this.vpc
      zone_id             = aws_route53_zone.this.zone_id
    }
  }
}
