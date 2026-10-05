# Basic zone

A public hosted zone for a domain, such as `example.org`, created with only the module's required inputs. The outputs are the zone's ID, for creating records in it, and its four name servers.

Route 53 answers queries for the domain only after the domain's registrar lists those name servers. Until then, the zone exists but nobody is sent to it.

## Run it

```shell
terraform init
terraform apply -var 'domain_name=<your domain>'
```

Remove it with `terraform destroy` and the same `-var`. The destroy fails if you have added records to the zone; delete them first. A hosted zone costs a monthly fee, except when it is deleted within 12 hours of being created.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The domain name for the hosted zone, such as example.org

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_name_servers"></a> [name_servers](#output_name_servers)

Description: Name servers to give the domain's registrar

#### <a name="output_zone_id"></a> [zone_id](#output_zone_id)

Description: ID of the hosted zone, for creating records in it
<!-- END_TF_DOCS -->
