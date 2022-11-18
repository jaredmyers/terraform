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
  region = "us-east-1"
}

# Grab latest ubuntu image
data "aws_ssm_parameter" "webserver_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# Create VPC
resource "aws_vpc" "ws_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ws_vpc"
  }
}

# Create Subnet 1, intended to be public
# Also associates subnet with VPC
# and enables auto IPv4 addresses w/ map public on launch
resource "aws_subnet" "public" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.ws_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_tf"
  }
}

# Create Subnet 2, intended to be private
# Also associates subnet with VPC
resource "aws_subnet" "private" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.ws_vpc.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "private_tf"
  }
}

# Create IGW for VPC internet/public access
# Also associates IGW with VPC
resource "aws_internet_gateway" "ws_vpc_igw" {
  vpc_id = aws_vpc.ws_vpc.id
  tags = {
    Name = "tf_igw"
  }
}

# Creates custom route table 
# Associates itself with VPC, creates route 
# and assoicates with the IGW
resource "aws_route_table" "ws_rt" {
  vpc_id = aws_vpc.ws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ws_vpc_igw.id

  }
  tags = {
    Name = "tf_rt"
  }
}

# Associates the public subnet w/the route table
resource "aws_route_table_association" "wspub_a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.ws_rt.id
}

# Creates SG for 22,80 traffic in
# Also ensures all traffic out 
# and associates with VPC
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "allow 22"
  vpc_id      = aws_vpc.ws_vpc.id
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

# Creates EC2 intended to be public
# Associates w/security group and public subnet
# Also links the pubkey and bootstraps nginx shellscript
resource "aws_instance" "webserver" {
  ami                         = data.aws_ssm_parameter.webserver_ami.value
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.webserver_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.public.id
  user_data                   = fileexists("script.sh") ? file("script.sh") : null


  tags = {
    Name = "TFwebserver"
  }
}

# Handles taking in the public key
resource "aws_key_pair" "webserver_key" {
  key_name   = "ec2-webserver"
  public_key = file("~/.ssh/ec2-webserver.pub")
}

output "webserver_public_ip" {
  value = aws_instance.webserver.public_ip
}
