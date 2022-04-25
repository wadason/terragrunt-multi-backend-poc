terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.7.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
