resource "aws_instance" "devops_server" {
  ami           = "ami-04bc53b7a499f5d37"
  instance_type = "t3.medium"

  tags = {
    Name = "DevOps-team2"
  }
}
