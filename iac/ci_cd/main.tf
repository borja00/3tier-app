locals {
  repositories      = ["api", "web", "grafana"]
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  action_secrets = {
    aws_access_key = {
      name  = "AWS_ACCESS_KEY_ID"
      value = aws_iam_access_key.ecr-deploy-user.0.id
    },
    aws_secret_access_key = {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = aws_iam_access_key.ecr-deploy-user.0.secret
    },
    aws_region = {
      name  = "AWS_REGION"
      value = var.shared_region
    },
    ecs_cluster = {
      name  = "ECS_CLUSTER"
      value = var.ecs_cluster_name
    },
    aws_s3_cdn_content_bucket = {
      name  = "AWS_S3_CDN_CONTENT_BUCKET"
      value = var.aws_s3_cdn_content_bucket
    },
  }
}

data "aws_partition" "current" {}


resource "aws_ecr_repository" "backend" {
  for_each = var.create_repositories ? toset(local.repositories) : toset({})
  name     = each.key

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_user_policy_attachment" "attach-ecr-push-role" {
  count      = var.create_repositories ? 1 : 0
  user       = aws_iam_user.ecr-deploy.0.name
  policy_arn = "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryFullAccess"

}

resource "aws_iam_user_policy_attachment" "attach-ecs-deploy-role" {
  count      = var.create_repositories ? 1 : 0
  user       = aws_iam_user.ecr-deploy.0.name
  policy_arn = "${local.policy_arn_prefix}/AmazonECS_FullAccess"

}

resource "aws_iam_user" "ecr-deploy" {
  count         = var.create_repositories ? 1 : 0
  name          = "${var.env_short}-ecr-deploy-deploy-${var.shared_region}"
  force_destroy = true
}

resource "aws_iam_access_key" "ecr-deploy-user" {
  count = var.create_repositories ? 1 : 0
  user  = aws_iam_user.ecr-deploy.0.name
}

data "github_repository" "repo" {
  full_name = var.github_repository
}


resource "github_actions_secret" "secrets" {
  for_each   = local.action_secrets
  repository = data.github_repository.repo.name
  //  environment = github_repository_environment.repo_environment.environment
  secret_name = each.value.name
  // TODO: Replace this with encrypted_value
  plaintext_value = each.value.value
}


