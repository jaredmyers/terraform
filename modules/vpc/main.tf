provider "aws" {
  region = var.region
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
