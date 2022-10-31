terraform {
  required_version = ">= 1.1.0"

  cloud {
    organization = "JazzTech"

    workspaces {
      name = "JazzTech"
    }
  }
  required_providers {
    aws = {
      version = ">= 3.73.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
