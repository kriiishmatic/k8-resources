######### bastion host #########
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t3.small"
  subnet_id     = local.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile = aws_iam_instance_profile.bastion.name

  user_data = file("bootstrap.sh")
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.common_name_suffix}-bastion"
    Purpose = "Bastion Host for EKS Cluster Access"
  }
  depends_on = [
    aws_iam_instance_profile.bastion
  ]
}

######## bastion IAM Role and Policies ########
resource "aws_iam_role" "bastion" {
  name = "${local.common_name_suffix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.common_name_suffix}-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}
resource "aws_security_group" "bastion_sg" {
  name        = "${local.common_name_suffix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.common_name_suffix}-bastion-sg"
    Purpose = "Bastion Host SG"
  }
}
###### SG Rules Between Bastion, EKS Cluster and Nodes ######
resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_eks_nodes" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_eks_control_plane" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
}
resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}