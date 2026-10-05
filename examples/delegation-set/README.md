# Shared name servers

Two or more public hosted zones that share one reusable delegation set: a group of four name servers that every zone in the set uses. At each domain's registrar you then enter the same four name servers, and they stay the same if a zone is deleted and created again with the same delegation set.

The example creates the delegation set with `aws_route53_delegation_set` and passes its ID to each module call as `delegation_set_id`.

## Run it

```shell
terraform init
terraform apply -var 'domain_names=["<first domain>", "<second domain>"]'
```

Remove it with `terraform destroy` and the same `-var`. The delegation set is deleted last, once no zone uses it.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_domain_names"></a> [domain_names](#input_domain_names)

Description: Two or more domain names, one hosted zone each, such as ["example.org", "example.net"]

Type: `list(string)`

### Outputs

The following outputs are exported:

#### <a name="output_name_servers"></a> [name_servers](#output_name_servers)

Description: The four name servers every zone uses, to give each domain's registrar

#### <a name="output_zone_ids"></a> [zone_ids](#output_zone_ids)

Description: ID of each hosted zone, by domain name
<!-- END_TF_DOCS -->
