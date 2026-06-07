locals {
  common_tags = {
    project     = "k8-volumes"
    environment = "dev"
  }
  # ami_id = data.aws_ami.eks_workstation.id
}