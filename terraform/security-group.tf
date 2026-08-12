data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins-security-group"
  description = "Security group for Practical Task Jenkins server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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