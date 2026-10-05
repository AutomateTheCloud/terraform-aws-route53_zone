# Private zone for two Regions

A private hosted zone, `internal.example.com`, for two VPCs you already have: one in `us-east-1` and one in `us-west-2`. Route 53 answers queries for the zone only from inside those VPCs, so the name can be any domain, including one you do not own.

The provider works in `us-west-2`, and the example sets the module's `region` to `us-east-1`. The first VPC has no Region of its own, so it is in the module's Region; the second sets `region = "us-west-2"`. It also shows the rest of the inputs a private zone takes: abbreviation overrides and an extra tag in `details`, a comment, and `force_destroy`.

Both VPCs must be in the account the provider uses, with DNS support and DNS hostnames turned on.

## Run it

```shell
terraform init
terraform apply -var 'vpc_id=<VPC ID in us-east-1>' -var 'second_vpc_id=<VPC ID in us-west-2>'
```

Remove it with `terraform destroy` and the same `-var` options. The VPCs are not changed, apart from the association.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_second_vpc_id"></a> [second_vpc_id](#input_second_vpc_id)

Description: ID of a VPC in us-west-2, the provider's Region. It needs DNS support and DNS hostnames turned on.

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of a VPC in us-east-1, such as vpc-0123456789abcdef0. It needs DNS support and DNS hostnames turned on.

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_zone"></a> [zone](#output_zone)

Description: ID, name and VPCs of the private hosted zone
<!-- END_TF_DOCS -->
