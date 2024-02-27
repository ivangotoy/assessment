terraform {
  backend "s3" {
    bucket         = "unreal-tf-state-bucket"
    key            = "hardened-server/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "unreal-tf-state-bucket"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
