provider "aws" {
  region = var.region
}

# Grab latest ubuntu image
data "aws_ssm_parameter" "latest_ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}
