# Terraform 
# VPC, 2 subnets (1 public, 1 private),
# IGW, routetable, SG, 1 EC2

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.main_region
}

# Module VPC, 2 subnets(1 public, 1 private)
module "vpc" {
  source = "./modules/vpc"
  region = var.main_region
}

# Creates SG for 22,80 traffic in
# Also ensures all traffic out 
# and associates with VPC
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "allow 22"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow http80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Grab latest ubuntu image
module "ami" {
		source = "./modules/ami"
		region = var.main_region
}

# Handles taking in the public key for EC2
resource "aws_key_pair" "webserver_key" {
  key_name   = "ec2-webserver"
  public_key = file("~/.ssh/ec2-webserver.pub")
}

# Creates EC2 intended to be public
# Associates w/security group and public subnet
# Also links the pubkey and bootstraps nginx shellscript
resource "aws_instance" "webserver" {
  ami                         = module.ami.latest_ubuntu_ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.webserver_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = module.vpc.public_subnet_id
  user_data                   = fileexists("/bootstraps/nginx.sh") ? file("/bootstraps/nginx.sh") : null

  tags = {
    Name = "TFwebserver"
  }
}

