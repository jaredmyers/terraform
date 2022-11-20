output "latest_ubuntu_ami_id" {
  value = data.aws_ssm_parameter.latest_ubuntu_ami.value
}
