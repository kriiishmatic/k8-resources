module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.common_name_suffix
  kubernetes_version = var.eks_version

  endpoint_public_access = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.public_subnet_ids
  control_plane_subnet_ids = local.public_subnet_ids
  create_security_group      = false
  create_node_security_group = false

  security_group_id      = aws_security_group.eks_cluster_sg.id
  node_security_group_id = aws_security_group.eks_node_sg.id

  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }

    aws-ebs-csi-driver = {}

    aws-efs-csi-driver = {}

    metrics-server = {}
  }

  eks_managed_node_groups = {
    blue = {
      create = true

      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = ["t3.small"]

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  
      }

      min_size     = 2
      desired_size = 3
      max_size     = 5

      labels = {
        nodegroup = "blue"
      }
    }

    green = {
      create = false

      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = ["t3.small"]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  
      }

      min_size     = 2
      desired_size = 3
      max_size     = 5

      labels = {
        nodegroup = "green"
      }
    }
  }
}

##### EBS CSI Driver #####
resource "aws_iam_role" "ebs_csi" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
  tags = {
    Name = "AmazonEKS_EBS_CSI_DriverRole"
    Purpose = "EBS CSI Driver Role for EKS"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_pod_identity_association" "ebs" {
  cluster_name    = module.eks.cluster_name

  namespace       = "kube-system"

  service_account = "ebs-csi-controller-sa"

  role_arn        = aws_iam_role.ebs_csi.arn
}

##### EFS CSI Driver #####
resource "aws_iam_role" "efs_csi" {
  name = "AmazonEKS_EFS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
  tags = {
    Name = "AmazonEKS_EFS_CSI_DriverRole"
    Purpose = "EFS CSI Driver Role for EKS"
  }
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  role       = aws_iam_role.efs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_eks_pod_identity_association" "efs" {
  cluster_name    = module.eks.cluster_name

  namespace       = "kube-system"

  service_account = "efs-csi-controller-sa"

  role_arn        = aws_iam_role.efs_csi.arn
}


