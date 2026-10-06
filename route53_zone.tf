# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A hosted zone is public unless it has at least one VPC, in which case it is private.
# Route 53 cannot turn one kind into the other.
resource "aws_route53_zone" "this" {
  name              = var.name
  comment           = local.comment
  delegation_set_id = var.delegation_set_id
  force_destroy     = var.force_destroy

  # Changes to this list are applied in place: the AWS provider associates the new VPCs
  # first, then disassociates the removed ones, because a private zone always needs one.
  dynamic "vpc" {
    for_each = var.vpcs
    content {
      vpc_id = vpc.value.id
      # A VPC without a Region is in the module's Region. null means the provider's.
      vpc_region = vpc.value.region != null ? vpc.value.region : var.region
    }
  }

  tags = local.tags
}
