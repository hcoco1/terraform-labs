output "ssh_connection_string" {
  value = "ssh -i ec2_rsa ec2-user@${aws_instance.ec2.public_ip}"
}