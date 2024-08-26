output "eb_cname" {
  value       = aws_elastic_beanstalk_environment.voxinsights_env.cname
  description = "CNAME of the Elastic Beanstalk environment"
}

# Add more outputs as needed