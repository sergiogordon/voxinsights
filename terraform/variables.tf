variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-west-2"
}

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  default     = "voxinsights"
}

variable "environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  default     = "voxinsights-env"
}

# Add more variables as needed