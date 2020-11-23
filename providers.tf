terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region = var.region-master
  alias = "region-master"
}


provider "aws" {
  profile = var.profile
  region = var.region-worker
  alias = "region-worker"
}
