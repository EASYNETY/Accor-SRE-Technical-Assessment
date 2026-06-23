variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment: prod, staging, dev."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for each AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs for each AZ."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "eks_node_groups" {
  description = "Managed node group definitions for the EKS cluster."
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    tags           = map(string)
  }))
  default = {
    redemption-core = {
      instance_types = ["t3.micro"]
      desired_size   = 3
      min_size       = 3
      max_size       = 8
      labels         = { role = "core" }
      tags           = { workload = "redemption-core" }
    }
  }
}
