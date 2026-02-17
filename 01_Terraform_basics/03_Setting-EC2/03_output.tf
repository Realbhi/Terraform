# are ouputed when the resources are provisioned

output "instance-public-ip" {
   value = aws_instance.ec2-instance.public_ip
}

output "instance-public-dns" {
   value = aws_instance.ec2-instance.public_dns
}
