data "aws_ami" "eks_workstation" {
  most_recent = true

  owners = ["854481201869"]

  filter {
    name   = "name"
    values = ["eks-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}