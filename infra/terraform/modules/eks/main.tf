data "aws_caller_identity" "current" {}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    #tfsec:ignore:aws-eks-no-public-cluster-access
    endpoint_public_access  = true
    #tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = merge({
    Name        = var.cluster_name
    Environment = var.environment
    Project     = "redemption"
  }, aws_iam_role.eks_cluster.tags)
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "nodegroup" {
  name               = "${var.cluster_name}-nodegroup-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodegroup_assume_role.json
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags = {
    Name        = "${var.cluster_name}-kms"
    Environment = var.environment
    Project     = "redemption"
  }
}

resource "aws_iam_policy" "redemption_api" {
  name        = "${var.cluster_name}-redemption-api-policy"
  description = "Least privilege policy for Redemption API pods"
  policy      = data.aws_iam_policy_document.redemption_api.json
}

resource "aws_iam_role" "redemption_api" {
  name               = "${var.cluster_name}-redemption-api-sa-role"
  assume_role_policy = data.aws_iam_policy_document.redemption_api_assume_role.json
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

resource "aws_iam_role_policy_attachment" "redemption_api_attach" {
  role       = aws_iam_role.redemption_api.name
  policy_arn = aws_iam_policy.redemption_api.arn
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

# ALB Controller Policy requires custom JSON download which isn't present
# resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
#   role       = aws_iam_role.alb_controller.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
# }

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id
  tags = {
    Environment = var.environment
    Project     = "redemption"
  }
}

resource "aws_eks_node_group" "managed" {
  for_each = var.eks_node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.nodegroup.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
  capacity_type  = "ON_DEMAND"

  labels = merge(each.value.labels, { environment = var.environment, app = "redemption" })
  tags = merge(each.value.tags, {
    Environment = var.environment
    Project     = "redemption"
  })
}

resource "aws_eks_addon" "vpc_cni" {
  addon_name    = "vpc-cni"
  cluster_name  = aws_eks_cluster.main.name
}

resource "aws_eks_addon" "coredns" {
  addon_name    = "coredns"
  cluster_name  = aws_eks_cluster.main.name
}

resource "aws_eks_addon" "kube_proxy" {
  addon_name    = "kube-proxy"
  cluster_name  = aws_eks_cluster.main.name
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["eks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "eks_nodegroup_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "redemption_api_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:redemption:redemption-api-sa"]
    }
  }
}

data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "redemption_api" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:redemption-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/redemption/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = ["arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:redemption-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}*"]
  }
}
