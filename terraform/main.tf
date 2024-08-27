provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "voxinsights-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "voxinsights-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "voxinsights-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "voxinsights-private-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "voxinsights-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_elastic_beanstalk_application" "voxinsights_app" {
  name        = var.app_name
  description = "VoxInsights Application"
}

resource "aws_elastic_beanstalk_environment" "voxinsights_env" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.voxinsights_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.7.2 running Python 3.8"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public.id},${aws_subnet.private.id}"
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

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "FRONTEND_URL"
    value     = "https://voxinsights-hbjn31m3q-sergiogordons-projects.vercel.app"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8000"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_ENDPOINT"
    value     = aws_api_gateway_deployment.voxinsights_api_deployment.invoke_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "WEBSOCKET_API_ENDPOINT"
    value     = aws_apigatewayv2_stage.websocket_stage.invoke_url
  }

  tags = {
    Environment = var.environment_name
    Project     = "VoxInsights"
  }
}

resource "aws_security_group" "eb_sg" {
  name        = "eb-security-group"
  description = "Security group for Elastic Beanstalk environment"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_api_gateway_rest_api.voxinsights_api.id}.execute-api.${var.aws_region}.amazonaws.com/32"]
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

# API Gateway
resource "aws_api_gateway_rest_api" "voxinsights_api" {
  name        = "voxinsights-api"
  description = "VoxInsights API Gateway"
}

resource "aws_api_gateway_resource" "transcribe" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  parent_id   = aws_api_gateway_rest_api.voxinsights_api.root_resource_id
  path_part   = "transcribe"
}

resource "aws_api_gateway_method" "transcribe_post" {
  rest_api_id   = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id   = aws_api_gateway_resource.transcribe.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "transcribe_integration" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id = aws_api_gateway_resource.transcribe.id
  http_method = aws_api_gateway_method.transcribe_post.http_method

  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_elastic_beanstalk_environment.voxinsights_env.cname}/transcribe"
}

resource "aws_api_gateway_resource" "record" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  parent_id   = aws_api_gateway_rest_api.voxinsights_api.root_resource_id
  path_part   = "record"
}

resource "aws_api_gateway_method" "record_post" {
  rest_api_id   = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id   = aws_api_gateway_resource.record.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "record_integration" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id = aws_api_gateway_resource.record.id
  http_method = aws_api_gateway_method.record_post.http_method

  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_elastic_beanstalk_environment.voxinsights_env.cname}/record"
}

resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  parent_id   = aws_api_gateway_rest_api.voxinsights_api.root_resource_id
  path_part   = "history"
}

resource "aws_api_gateway_method" "history_get" {
  rest_api_id   = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "history_integration" {
  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  resource_id = aws_api_gateway_resource.history.id
  http_method = aws_api_gateway_method.history_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_elastic_beanstalk_environment.voxinsights_env.cname}/history"
}

resource "aws_api_gateway_deployment" "voxinsights_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.transcribe_integration,
    aws_api_gateway_integration.record_integration,
    aws_api_gateway_integration.history_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.voxinsights_api.id
  stage_name  = "prod"
}

# WebSocket API
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "voxinsights-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect_integration.id}"
}

resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "http://${aws_elastic_beanstalk_environment.voxinsights_env.cname}/ws-connect"
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id = aws_apigatewayv2_api.websocket_api.id
  name   = "prod"
}

# Outputs
output "api_gateway_url" {
  value = aws_api_gateway_deployment.voxinsights_api_deployment.invoke_url
}

output "websocket_url" {
  value = aws_apigatewayv2_stage.websocket_stage.invoke_url
}