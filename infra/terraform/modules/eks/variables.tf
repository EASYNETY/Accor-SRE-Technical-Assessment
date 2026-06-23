variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC id for the cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids for EKS."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet ids for EKS."
  type        = list(string)
}

variable "eks_node_groups" {
  description = "Managed node groups definitions."
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    tags           = map(string)
  }))
}

variable "environment" {
  description = "Environment tag."
  type        = string
}
