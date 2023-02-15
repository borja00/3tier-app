
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "tenant-terraform-state-${local.aws_region}"
    key            = "${local.env_short}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-lock-table-${local.aws_region}"
  }
}

locals {
  main_name                 = "tenant"
  aws_region                = "eu-west-1"
  env_long                  = "development"
  env_short                 = "dev"
  aws_account_id            = "541262847589"
  vpc_name                  = "tenant-vpc-${local.aws_region}-${local.env_short}"
  ecs_cluster_name          = "${local.env_long}-tenant-ecs-cluster-${local.aws_region}"
  aws_s3_cdn_content_bucket = "${local.env_long}-cdn-${local.aws_region}"

}
