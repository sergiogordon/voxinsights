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

variable "vpc_id" {
  description = "The ID of the VPC in which to launch the Elastic Beanstalk environment"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

# Add more variables as needed