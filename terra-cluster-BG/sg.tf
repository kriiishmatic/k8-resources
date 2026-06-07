######SGS ######
resource "aws_security_group" "eks_cluster_sg" {  
  name        = "${local.common_name_suffix}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.common_name_suffix}-cluster-sg"
    Purpose = "EKS Cluster Control Plane SG"
  }
}

resource "aws_security_group" "eks_node_sg" {
  name        = "${local.common_name_suffix}-node-sg"
  description = "Security group for EKS cluster nodes"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.common_name_suffix}-node-sg"
    Purpose = "EKS Cluster Nodes SG"
  }
}

##### SG rules for EKS cluster and nodes #####
resource "aws_security_group_rule" "eks_node_eks_control_plane" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  from_port         = 0
  protocol          = "-1"
  to_port           = 0

}
resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  security_group_id = aws_security_group.eks_cluster_sg.id

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_control_plane_eks_node" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
}

resource "aws_security_group_rule" "node_egress" {
  type              = "egress"
  security_group_id = aws_security_group.eks_node_sg.id

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}
