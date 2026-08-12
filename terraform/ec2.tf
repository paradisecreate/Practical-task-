data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "devops_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name      = "Your Instance"
    ManagedBy = "Terraform"
  }
}

resource "aws_eip" "devops_server_eip" {
  domain = "vpc"

  tags = {
    Name      = "Your Instance-eip"
    ManagedBy = "Terraform"
  }
}

resource "aws_eip_association" "devops_server_eip_assoc" {
  instance_id   = aws_instance.devops_server.id
  allocation_id = aws_eip.devops_server_eip.id
}

output "devops_server_public_ip" {
  description = "Static public IP of the Jenkins EC2 server"
  value       = aws_eip.devops_server_eip.public_ip
}