variable "shared_region" {
  description = "AWS region"
}

variable "env_long" {
  description = "Long environment name"
}

variable "env_short" {
  description = "Short environment name"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
}

variable "create_repositories" {
  description = "Create repositories flag"
  default = false
}

variable "github_repository" {
  description = "Github public repository where the project is hosted"
}

variable "aws_account_id" {
  description = "AWS Account Id"
}

variable "aws_s3_cdn_content_bucket" {
  description = "AWS S3 Bucket name for cdn content"
}





