locals {
  common_name_suffix = "${var.project_name}-${var.environment}"
    vpc_id = "vpc-073f068d99a28006a"
    public_subnet_ids = [
    "subnet-09e1785d7668c8762",
    "subnet-0bd99b0dc81e73657"
  ]
}