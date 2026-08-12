# ============================================================
# IAM ROLE FOR EC2 / JENKINS
# ============================================================

resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "jenkins-ec2-role"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# JENKINS PERMISSIONS FOR S3 + ECR
# ============================================================

resource "aws_iam_role_policy" "jenkins_permissions" {
  name = "jenkins-s3-ecr-policy"
  role = aws_iam_role.jenkins_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # ------------------------------------------------------
      # ECR authorization
      # Required for:
      # aws ecr get-login-password
      # ------------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      # ------------------------------------------------------
      # Push Docker images to our ECR repository
      # ------------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = aws_ecr_repository.website.arn
      },

      # ------------------------------------------------------
      # S3 bucket access
      # Jenkins uses:
      # aws s3 sync website/ s3://bucket/
      # ------------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = aws_s3_bucket.website.arn
      },

      # ------------------------------------------------------
      # S3 object access
      # ------------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}


# ============================================================
# SSM / SESSION MANAGER
#
# Allows us to connect to EC2 through:
# EC2 -> Connect -> Session Manager
# without SSH keys.
# ============================================================

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# INSTANCE PROFILE
#
# EC2 cannot directly receive an IAM role.
# The role is attached through an Instance Profile.
# ============================================================

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}