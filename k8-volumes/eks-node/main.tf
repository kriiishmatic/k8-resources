resource "aws_instance" "eks-volumes" {
    ami = "ami-0220d79f3f480ecf5" # Amazon Linux 2 AMI (HVM), SSD Volume Type
    instance_type = "t3.small"
    vpc_security_group_ids = [aws_security_group.eks-node.id]
    subnet_id = "subnet-09e1785d7668c8762" # This is my default subnet
    root_block_device {
        volume_size = 50
        volume_type = "gp3"
    }

    user_data = file("bootstrap.sh")
    tags = merge(
        local.common_tags,
        {
            Name = "eks"
   
        }
    )
    depends_on = [aws_security_group.eks-node]
}

resource "aws_security_group" "eks-node" {
    name = "eks-node-sg"
    description = "Security group for EKS node volumes"
    

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

