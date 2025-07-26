terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = "us-east-1"
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY come from env vars
}