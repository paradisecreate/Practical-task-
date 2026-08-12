# ============================================================
# AMAZON LINUX 2023 AMI
# ============================================================

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


# ============================================================
# DEFAULT VPC
#
# We use the account's default VPC for this practical task.
# ============================================================

data "aws_vpc" "default" {
  default = true
}


# ============================================================
# SECURITY GROUP
# ============================================================

resource "aws_security_group" "jenkins" {
  name        = "jenkins-security-group"
  description = "Security group for Practical Task Jenkins server"
  vpc_id      = data.aws_vpc.default.id

  # Jenkins Web UI
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow EC2 to access Internet:
  # GitHub, AWS APIs, package repositories, etc.
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "jenkins-security-group"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# EC2 INSTANCE
# ============================================================

resource "aws_instance" "devops_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Gives EC2/Jenkins permissions for:
  # S3 + ECR + SSM
  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  # Jenkins port 8080
  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  # Automatically bootstrap the new EC2.
  #
  # user_data.sh:
  #   -> installs Ansible
  #   -> clones repository
  #   -> runs ansible/playbook.yml
  #   -> installs Docker + Jenkins
  user_data = file("${path.module}/user_data.sh")

  # If user_data.sh changes, recreate EC2 so the new bootstrap
  # actually executes on a fresh instance.
  user_data_replace_on_change = true

  tags = {
    Name      = "Your Instance"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# ELASTIC IP
# ============================================================

resource "aws_eip" "devops_server_eip" {
  domain = "vpc"

  tags = {
    Name      = "Your Instance-eip"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# ATTACH ELASTIC IP TO EC2
# ============================================================

resource "aws_eip_association" "devops_server_eip_assoc" {
  instance_id   = aws_instance.devops_server.id
  allocation_id = aws_eip.devops_server_eip.id
}


# ============================================================
# OUTPUT
# ============================================================

output "devops_server_public_ip" {
  description = "Static public IP of the Jenkins EC2 server"
  value       = aws_eip.devops_server_eip.public_ip
}