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
}

data "aws_iam_instance_profile" "bootcamp" {
  name = "Bootcamp-Instance-Profile"
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    "sg-005e05ce419f3ec0d"
  ]

  iam_instance_profile = data.aws_iam_instance_profile.bootcamp.name

  user_data = templatefile("${path.module}/user_data.sh", {
    repository = "https://github.com/paradisecreate/Practical-task-.git"
    branch     = "terraform-automation"
  })

  user_data_replace_on_change = true

  tags = {
    Name = "your-instance"
  }
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}