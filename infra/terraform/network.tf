# Reuse the account's default VPC and its existing default subnets. No VPC,
# subnet, route table, or internet gateway is created by this configuration.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  # ALB and RDS DB subnet groups require subnets in at least two AZs.
  default_subnet_ids = slice(data.aws_subnets.default_vpc.ids, 0, 2)
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-${var.environment}"
  subnet_ids = local.default_subnet_ids
}
