terraform {
  source = "./../../..//iac/node-3tier-app"
}

locals {
  env_vars   = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  aws_region = local.env_vars.locals.aws_region
  env_long   = local.env_vars.locals.env_long
  env_short  = local.env_vars.locals.env_short
  vpc_name   = local.env_vars.locals.vpc_name
}


inputs = {
  aws_account_id            = local.env_vars.locals.aws_account_id
  shared_region             = local.aws_region
  env_long                  = local.env_long
  env_short                 = local.env_short
  vpc_name                  = local.vpc_name
  create_repositories       = true
  create_services           = true
  create_database           = true
  github_repository         = "borja00/3tier-app"
  instance_count            = 3
  ecs_cluster_name          = local.env_vars.locals.ecs_cluster_name
  aws_s3_cdn_content_bucket = local.env_vars.locals.aws_s3_cdn_content_bucket

}

include {
  path = find_in_parent_folders()
}
