data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    local.jenkins_security_group_id
  ]

  iam_instance_profile = data.aws_iam_instance_profile.bootcamp.name

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  depends_on = [
    aws_ecr_repository.website,
    aws_s3_bucket.website,
    aws_s3_bucket_website_configuration.website
  ]

  tags = {
    Name    = "your-instance"
    Project = "practical-task"
  }
}

resource "aws_eip" "jenkins" {
  domain = "vpc"

  tags = {
    Name    = "your-instance-eip"
    Project = "practical-task"
  }
}

resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  value = aws_eip.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}