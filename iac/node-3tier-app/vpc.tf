locals {
  tags = {
    Terraform   = "true"
    Environment = var.env_long
  }
}

data "aws_availability_zones" "available" {
  count = var.create_vpc ? 1 : 0

}



module "vpc" {
  // https://github.com/terraform-aws-modules/terraform-aws-vpc
  count   = var.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.0.names
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}

