variable "aws_region" {
  description = "AWS region for the VPC."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to VPC resources."
  type        = map(string)
}
