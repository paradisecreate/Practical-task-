resource "aws_ecr_repository" "website" {
  name = "your-task-website"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "your-task-website"
    ManagedBy = "Terraform"
  }
}