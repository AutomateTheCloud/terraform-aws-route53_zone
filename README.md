# Terraform module for Amazon Route 53 hosted zones

Creates a Route 53 hosted zone: a public zone that answers DNS queries for a domain on the internet, or a private zone that answers only inside the VPCs you associate with it.

A zone created with only the required inputs is public, has its own name servers, and cannot be destroyed while it holds records other than its own NS and SOA records, so a `terraform destroy` cannot delete records you did not mean to delete.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Domain name | Required | `name` |
| Public or private | Public | `vpcs` (any VPC makes it private) |
| Name servers | The zone's own | `delegation_set_id` |
| Delete records on destroy | No | `force_destroy` |
| Comment | `Public hosted zone for <name>`, or `Private` for a private zone | `comment` |
| Region of the VPCs | The provider's | `region`, `vpcs[*].region` |

## Usage

```hcl
module "route53_zone" {
  source  = "AutomateTheCloud/route53_zone/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  name = "example.org"
}
```

`details` and `name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on the zone. The zone answers for `example.org` once the domain's registrar lists the four name servers in the `metadata` output's `route53_zone.name_servers`.

A private zone answers only inside the VPCs you list. A VPC without a Region is in the module's Region, which is the provider's unless you set `region`:

```hcl
module "route53_zone_private" {
  source  = "AutomateTheCloud/route53_zone/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Internal Services", environment = "Production" }
  name    = "internal.example.org"

  vpcs = [
    { id = "vpc-0123456789abcdef0" },                       # in us-west-2
    { id = "vpc-0fedcba9876543210", region = "us-east-1" }, # in another Region
  ]
}
```

Route 53 is a global service, so the hosted zone itself has no Region. `region` sets the Region of the VPCs and the Region reported in `metadata`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the hosted zone belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a hosted zone in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the hosted zone, the certificate for its domain, the load balancer and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_zone" {
  source  = "AutomateTheCloud/route53_zone/aws"
  version = "~> 1.0"

  details = local.details
  name    = "example.org"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_zone.metadata.route53_zone.zone_id` for the zone's ID, or `module.site_zone.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. A hosted zone costs a monthly fee from the moment it exists; Route 53 does not charge for a zone deleted within 12 hours of being created.

- [Basic zone](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/tree/main/examples/basic): a public hosted zone for a domain.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/tree/main/examples/complete): a private hosted zone for two existing VPCs in different Regions, with most of the module's inputs.
- [Shared name servers](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/tree/main/examples/delegation-set): two public hosted zones that use one reusable delegation set, so they have the same name servers.

## Things to know

### Public and private zones

A zone with no `vpcs` is public, and a zone with at least one is private. Route 53 cannot turn one kind into the other. The AWS provider does not replace the zone when the list goes from empty to not empty, or back: the plan shows an in-place update, and the apply then fails with an error from Route 53. By then the provider has already changed the zone's default comment to the new kind, so the comment is wrong until you put `vpcs` back and apply again.

To change the kind, create a new zone with another module call, move the records, then remove the old one.

### Making a public zone answer for its domain

Creating a public zone does not move the domain's DNS to it. Route 53 answers for the domain only after the domain's registrar lists the zone's name servers, from the `metadata` output's `route53_zone.name_servers`. For a subdomain such as `dev.example.org`, create an `NS` record for it in the parent zone instead.

### VPC associations

The module manages the full list of VPCs. Adding a VPC to `vpcs` associates it, and removing one disassociates it, without replacing the zone. The AWS provider associates the new VPCs before it disassociates the old ones, because a private zone always needs at least one.

Because the module manages the full list, an apply also disassociates any VPC associated outside this module, for example with an `aws_route53_zone_association` resource or in the console. List every VPC in `vpcs` instead. A VPC in another AWS account needs an authorization from the zone's account first, which this module does not create.

Each VPC needs DNS support and DNS hostnames turned on (`enable_dns_support` and `enable_dns_hostnames` on `aws_vpc`) to resolve the private zone.

### Records

The module creates the zone and nothing in it except the `NS` and `SOA` records that Route 53 adds. Create other records with `aws_route53_record`, using the `metadata` output's `route53_zone.zone_id`.

### Destroying a zone

With `force_destroy = false`, the default, Route 53 refuses to delete a zone that still has records other than its own `NS` and `SOA` records, and the destroy fails. Delete the records first, or set `force_destroy = true` and apply before destroying, to delete every record in the zone, including records created outside Terraform.

### Changing the name or the delegation set

Changing `name` or `delegation_set_id` replaces the zone. The new zone starts empty and, for a public zone, gets new name servers, so the domain stops resolving until its registrar lists them. The plan shows the zone as replaced; check it before applying.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against a mocked AWS provider, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_zone#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The domain name of the hosted zone, such as `example.com`, or `internal.example.com` for a private zone. Without a trailing period. Changing it replaces the zone with a new, empty one.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_comment"></a> [comment](#input_comment)

Description: A note about the hosted zone, shown in the Route 53 console, 1 to 256 characters. Defaults to `null`, which sets `Public hosted zone for <name>` or `Private hosted zone for <name>`, cut to 256 characters.

Type: `string`

Default: `null`

#### <a name="input_delegation_set_id"></a> [delegation_set_id](#input_delegation_set_id)

Description: The ID of a reusable delegation set, such as `N0123456789ABCDEFGHIJ`, to give a public hosted zone the same four name servers as the other zones that use it. Public zones only: it cannot be combined with `vpcs`. Defaults to `null`, which gives the zone its own name servers. Changing it replaces the zone with a new, empty one.

Type: `string`

Default: `null`

#### <a name="input_force_destroy"></a> [force_destroy](#input_force_destroy)

Description: Delete every record in the hosted zone when the zone is destroyed, including records created outside Terraform. Defaults to `false`: Route 53 then refuses to delete a zone that holds any record other than its own NS and SOA records, so a destroy cannot remove records you did not mean to remove.

Type: `bool`

Default: `false`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region the module works in, such as `us-west-2`. Route 53 is a global service, so the hosted zone itself has no Region. This sets the Region reported in the `metadata` output, and the Region of each VPC in `vpcs` that does not set its own. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_vpcs"></a> [vpcs](#input_vpcs)

Description: The VPCs to associate with the hosted zone. Setting at least one makes the zone private: Route 53 answers queries for it only from inside these VPCs. Defaults to none, which makes the zone public. A zone cannot change between public and private after it is created; see [Public and private zones](https://github.com/AutomateTheCloud/terraform-aws-route53_zone#public-and-private-zones).

- `id` - (Required) The VPC ID, such as `vpc-0123456789abcdef0`.
- `region` - (Optional) The VPC's Region, such as `us-west-2`. Defaults to the module's `region`.

The module manages the full list: on each apply it associates VPCs that were added and disassociates VPCs that were removed, including VPCs associated outside this module. The VPCs must be in the same AWS account as the hosted zone.

Type:

```hcl
list(object({
    id     = string
    region = optional(string)
  }))
```

Default: `[]`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the module's Region.
- `route53_zone` - The hosted zone: its `zone_id` (use this for records), `arn`, `name`, `name_servers` (give these to the domain's registrar to make a public zone answer for the domain), `primary_name_server`, `comment`, `delegation_set_id`, `force_destroy`, `vpc` (the associated VPCs, each with its `vpc_id` and `vpc_region`), `tags` and `tags_all`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-route53_zone/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
