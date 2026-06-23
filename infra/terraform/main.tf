module "vpc" {
  source               = "./modules/vpc"
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "redemption-${var.environment}"
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  eks_node_groups    = var.eks_node_groups
  environment        = var.environment
}

module "monitoring" {
  source       = "./modules/monitoring"
  cluster_name = module.eks.cluster_name
}

