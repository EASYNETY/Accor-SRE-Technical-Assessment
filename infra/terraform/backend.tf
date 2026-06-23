terraform {
  backend "s3" {
    bucket         = "redemption-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "redemption-terraform-lock"
    encrypt        = true
  }
}
