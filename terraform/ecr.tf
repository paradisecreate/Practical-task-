resource "aws_ecr_repository" "website" {
  name                 = "your-task-website"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "your-task-website"
    Project = "practical-task"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.website.repository_url
}