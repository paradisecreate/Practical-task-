resource "aws_instance" "devops_server" {
  ami           = "ami-04bc53b7a499f5d37"
  instance_type = "t3.medium"

  tags = {
    Name = "DevOps-team2"
  }
}


# Static public IP for the EC2 instance
resource "aws_eip" "devops_server_eip" {
  domain = "vpc"

  tags = {
    Name = "DevOps-team2-eip"
  }
}


# Attach Elastic IP to our EC2 instance
resource "aws_eip_association" "devops_server_eip_assoc" {
  instance_id   = aws_instance.devops_server.id
  allocation_id = aws_eip.devops_server_eip.id
}


# Show the static IP after terraform apply
output "devops_server_public_ip" {
  value = aws_eip.devops_server_eip.public_ip
}