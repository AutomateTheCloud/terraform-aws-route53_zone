# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "comment" {
  description = <<-EOT
    A note about the hosted zone, shown in the Route 53 console, 1 to 256 characters. Defaults to `null`, which sets `Public hosted zone for <name>` or `Private hosted zone for <name>`, cut to 256 characters.
  EOT
  type        = string
  default     = null

  # The AWS provider replaces an empty comment with "Managed by Terraform".
  validation {
    condition     = var.comment == null || try(length(var.comment) >= 1 && length(var.comment) <= 256, false)
    error_message = "comment must be 1 to 256 characters, or null for the default."
  }
}

variable "delegation_set_id" {
  description = <<-EOT
    The ID of a reusable delegation set, such as `N0123456789ABCDEFGHIJ`, to give a public hosted zone the same four name servers as the other zones that use it. Public zones only: it cannot be combined with `vpcs`. Defaults to `null`, which gives the zone its own name servers. Changing it replaces the zone with a new, empty one.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.delegation_set_id == null || can(regex("^[A-Za-z0-9]{1,32}$", var.delegation_set_id))
    error_message = "delegation_set_id must be a delegation set ID, such as N0123456789ABCDEFGHIJ, without the /delegationset/ prefix."
  }

  validation {
    condition     = var.delegation_set_id == null || length(var.vpcs) == 0
    error_message = "delegation_set_id is for public hosted zones only, so it cannot be combined with vpcs."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_zone#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "force_destroy" {
  description = <<-EOT
    Delete every record in the hosted zone when the zone is destroyed, including records created outside Terraform. Defaults to `false`: Route 53 then refuses to delete a zone that holds any record other than its own NS and SOA records, so a destroy cannot remove records you did not mean to remove.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "name" {
  description = <<-EOT
    The domain name of the hosted zone, such as `example.com`, or `internal.example.com` for a private zone. Without a trailing period. Changing it replaces the zone with a new, empty one.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) <= 253 && can(regex("^([A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?\\.)*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", var.name))
    error_message = "name must be a domain name, such as example.com, with no trailing period."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region the module works in, such as `us-west-2`. Route 53 is a global service, so the hosted zone itself has no Region. This sets the Region reported in the `metadata` output, and the Region of each VPC in `vpcs` that does not set its own. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "vpcs" {
  description = <<-EOT
    The VPCs to associate with the hosted zone. Setting at least one makes the zone private: Route 53 answers queries for it only from inside these VPCs. Defaults to none, which makes the zone public. A zone cannot change between public and private after it is created; see [Public and private zones](https://github.com/AutomateTheCloud/terraform-aws-route53_zone#public-and-private-zones).

    - `id` - (Required) The VPC ID, such as `vpc-0123456789abcdef0`.
    - `region` - (Optional) The VPC's Region, such as `us-west-2`. Defaults to the module's `region`.

    The module manages the full list: on each apply it associates VPCs that were added and disassociates VPCs that were removed, including VPCs associated outside this module. The VPCs must be in the same AWS account as the hosted zone.
  EOT
  type = list(object({
    id     = string
    region = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for v in var.vpcs : can(regex("^vpc-[0-9a-f]{8,17}$", v.id))])
    error_message = "Each vpcs[*].id must be a VPC ID, such as vpc-0123456789abcdef0."
  }

  validation {
    condition     = alltrue([for v in var.vpcs : v.region == null || can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", v.region))])
    error_message = "Each vpcs[*].region must be a Region name, such as us-west-2."
  }

  validation {
    condition     = length(distinct([for v in var.vpcs : v.id])) == length(var.vpcs)
    error_message = "Each VPC can be listed only once in vpcs."
  }
}
