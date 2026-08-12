resource "aws_ecr_repository" "website" {
  name         = "your-task-website"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "your-task-website"
    ManagedBy = "Terraform"
  }
}