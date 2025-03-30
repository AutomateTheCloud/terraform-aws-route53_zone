resource "aws_route53_zone" "this" {
  name              = var.name
  comment           = var.comment
  force_destroy     = var.force_destroy
  delegation_set_id = var.delegation_set_id

  dynamic "vpc" {
    iterator = vpc
    for_each = var.vpc
    content {
      vpc_id     = vpc.value.id
      vpc_region = vpc.value.region
    }
  }

  lifecycle {
    ignore_changes = [vpc]
  }

  tags     = local.tags
  provider = aws.this
}
