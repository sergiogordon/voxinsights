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

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.subnet_ids)
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = var.environment_name
  }

  tags = {
    Environment = var.environment_name
    Project     = "VoxInsights"
  }
}

resource "aws_security_group" "eb_sg" {
  name        = "eb-security-group"
  description = "Security group for Elastic Beanstalk environment"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "EB Security Group"
    Environment = var.environment_name
    Project     = "VoxInsights"
  }
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

resource "aws_iam_role_policy_attachment" "eb_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eb_instance_role.name
}

# Add more resources and configurations as needed