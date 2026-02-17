#Get ALL Public IPs and public DNS

output "instance-public-ip" {
   value = aws_instance.ec2-instance[*].public_ip
}

output "instance-public-dns" {
   value = aws_instance.ec2-instance[*].public_dns
}
