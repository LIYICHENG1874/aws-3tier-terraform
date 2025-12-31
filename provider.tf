terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # [Note] In production, use S3 & DynamoDB for Remote State and Locking
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "state/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}

provider "aws" {
  region = var.region
}