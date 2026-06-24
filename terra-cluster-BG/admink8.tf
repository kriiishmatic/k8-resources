#################################
# IAM User
#################################

resource "aws_iam_user" "jane" {
  name = "jane"
}

#################################
# Policy for kubeconfig generation
#################################

resource "aws_iam_policy" "jane_eks_access" {

  name = "jane-eks-describe"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = "arn:aws:eks:us-east-1:854481201869:cluster/Roboshop-dev"
      }
    ]
  })
}

#################################
# Attach policy to Jane
#################################

resource "aws_iam_user_policy_attachment" "jane" {

  user       = aws_iam_user.jane.name

  policy_arn = aws_iam_policy.jane_eks_access.arn
}

#################################
# EKS Access Entry
#################################

resource "aws_eks_access_entry" "jane" {

  cluster_name = "Roboshop-dev"

  principal_arn = aws_iam_user.jane.arn

  kubernetes_groups = [
    "trainees"
  ]

  type = "STANDARD"
}