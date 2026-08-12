# Made more flexible using ChatGPT suggestions
# Find the latest Amazon Linux 2023 AMI automatically
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

# Create EC2 instance
resource "aws_instance" "devops_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = {
    Name = "Your Instance"
  }
}

# Create static public IP
resource "aws_eip" "devops_server_eip" {
  domain = "vpc"

  tags = {
    Name = "Your Instance-eip"
  }
}

# Attach static IP to EC2
resource "aws_eip_association" "devops_server_eip_assoc" {
  instance_id   = aws_instance.devops_server.id
  allocation_id = aws_eip.devops_server_eip.id
}

# Display static IP after terraform apply
output "devops_server_public_ip" {
  value = aws_eip.devops_server_eip.public_ip
}