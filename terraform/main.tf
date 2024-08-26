provider "aws" {
  region = var.aws_region
}

resource "aws_elastic_beanstalk_application" "voxinsights_app" {
  name        = var.app_name
  description = "VoxInsights Application"
}

resource "aws_elastic_beanstalk_environment" "voxinsights_env" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.voxinsights_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.13 running Python 3.8"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # Add more settings as needed
}

# IAM role and instance profile
resource "aws_iam_role" "eb_instance_role" {
  name = "eb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "eb-ec2-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.eb_instance_role.name
}

# Add more resources and configurations as needed