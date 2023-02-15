terraform {
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "3.74.1"
    }

    github = {
      source  = "integrations/github"
      version = "4.20.0"
    }



  }
  required_version = ">= 1.0.0"
}
