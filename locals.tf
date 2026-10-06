# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # Any VPC makes the zone private. The list's length comes from the inputs, so this is
  # known at plan time even when the VPC IDs are not.
  private_zone = length(var.vpcs) > 0

  comment = var.comment != null ? var.comment : substr("${local.private_zone ? "Private" : "Public"} hosted zone for ${var.name}", 0, 256)
}
