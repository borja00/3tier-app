variable "shared_region" {
  default     = "eu-central-1"
  description = "AWS region"
}

variable "env_long" {
  description = "Long environment name"
}

variable "env_short" {
  description = "Short environment name"
}

variable "create_vpc" {
  default     = true
  description = "Flag to not deploy VPC"
}

variable "vpc_name" {
  description = "Name of the VPC"
}

# ECS

variable "create_services" {
  description = ""
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}

variable "instance_count" {
  description = "Number of docker containers instances to run for api and web"
  default     = 1
}

variable "aws_account_id" {
  description = "AWS Account Id"
}


# CDN

variable "aws_s3_cdn_content_bucket" {
  description = "AWS S3 Bucket name for cdn content"
}



# Database

variable "create_database" {
  description = "Create database flag"
  default     = true
}
