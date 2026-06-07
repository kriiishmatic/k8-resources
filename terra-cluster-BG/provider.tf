terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.42"
    }
  }

  backend "s3" {
    bucket = "terraform-backend-state-ecs"
    key    = "K8-cluster-BG-projectK"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}