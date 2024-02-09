provider "aws" {
    region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable name_prefix {}
variable my_ip {}
variable instance_type {}
variable keypair {}

resource "aws_vpc" "app-vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true
    tags = {
        Name: "${var.name_prefix}-vpc"
    }
}

resource "aws_subnet" "app-subnet-1" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.name_prefix}-subnet-1"
    }
 }

resource "aws_internet_gateway" "app-igw" {
    vpc_id = aws_vpc.app-vpc.id
    tags = {
        Name: "${var.name_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-route-table" {
    default_route_table_id = aws_vpc.app-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app-igw.id
    }
    tags = {
        Name: "${var.name_prefix}-main-route-table"
    }
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.app-vpc.id

    ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 8080
      to_port = 8080
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids = []
    }
    
    tags = {
      Name: "${var.name_prefix}-default-sg"
    }
}

output "ec2_public_ip" {
    value = aws_instance.app-server.public_ip
}

resource "aws_instance" "app-server" {
    ami = "ami-06aa3f7caf3a30282"
    instance_type = var.instance_type
    subnet_id = aws_subnet.app-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = var.keypair

    user_data = file("script.sh")
    user_data_replace_on_change = true
                    
    tags = {
      Name: "${var.name_prefix}-server"
    }
}