
resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role = aws_iam_role.ebs_csi.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  cloudwatch_log_group_retention_in_days = 7

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  control_plane_subnet_ids = var.private_subnet_ids

  # Cluster API access
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = [var.admin_cidr]

  enable_cluster_creator_admin_permissions = true

  # EKS Add-ons
  addons = {
    coredns    = {}
    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }

    aws-ebs-csi-driver = {
      before_compute = true

      pod_identity_association = [
        {
          role_arn        = aws_iam_role.ebs_csi.arn
          service_account = "ebs-csi-controller-sa"
        }
      ]
    }
  }

  # Two Spot worker nodes
  eks_managed_node_groups = {
    spot = {
      name          = "dasmeta-spot"
      capacity_type = "SPOT"

      instance_types = [
        "t3.medium",
        "t3a.medium"
      ]

      min_size     = 2
      max_size     = 2
      desired_size = 2

      subnet_ids = var.private_subnet_ids

      labels = {
        Environment = "dev"
        NodeType    = "spot"
      }
    }
  }

  tags = var.tags
}
