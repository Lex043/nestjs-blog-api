// default aws vpc
data "aws_vpc" "default" {
  default = true
}

// terraform state bucket
terraform {
  backend "s3" {
    bucket = "lex-blog-api-tfstate"
    key    = "blog-api/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_cloudwatch_log_group" "blog_api" {
  name              = "/ecs/blog-api"
  retention_in_days = 7
}

// rds security group
resource "aws_security_group" "rds" {
  name        = "blog-db-sg"
  description = "Security group for PostgreSQl"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "blog-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id = aws_security_group.rds.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

// security group for the ALB
resource "aws_security_group" "lb_sg" {
  name        = "blog-api-lb-sg"
  description = "Security group for the ALB"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "blog-api-lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 80
  to_port             = 80
  ip_protocol         = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb_outbound" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol         = "-1"
}

// security group for the Fargate tasks — only reachable from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "blog-api-ecs-sg"
  description = "Security group for Fargate tasks"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "blog-api-ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_lb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol         = "-1"
}

// ECS task execution role
resource "aws_iam_role" "ecs_execution" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// target group — where the ALB sends traffic
resource "aws_lb_target_group" "blog_api" {
  name_prefix = "blog-"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path = "/"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "blog_api" {
  load_balancer_arn = aws_lb.blog_api_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_api.arn
  }
}

// subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "blog" {
  name       = "blog-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

//alb
resource "aws_lb" "blog_api_alb" {
  name               = "blog-api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

//ecs service
resource "aws_ecs_service" "blog_api" {
  name            = "nestjs-blog-api"
  cluster         = aws_ecs_cluster.blog_api_cluster.id
  task_definition = aws_ecs_task_definition.blog_api_service.arn
  launch_type     = "FARGATE"
  desired_count   = 2

 network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blog_api.arn
    container_name    = "blog-api"
    container_port    = 3000
  }

  depends_on = [aws_lb_listener.blog_api]
}

//ecs cluster
resource "aws_ecs_cluster" "blog_api_cluster" {
  name = "blog-api-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

//ecs task definition
resource "aws_ecs_task_definition" "blog_api_service" {
  family = "blog-api-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "blog-api"
      image     = "10603/nestjs-blog-api"
      essential = true
      portMappings = [
        {
          containerPort = 3000
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.blog.address
        },
        {
          name  = "DB_PORT"
          value = tostring(aws_db_instance.blog.port)
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.blog.db_name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.blog.username
        },
        {
          name  = "DB_PASS"
          value = var.db_password
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
      logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group"         = "/ecs/blog-api"
                "awslogs-region"        = "us-east-1"
                "awslogs-stream-prefix" = "blog-api"
            }
        }
    },
  ])
}

// postgresql rds
resource "aws_db_instance" "blog" {
  allocated_storage   = 10
  db_name             = "blog"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.micro"
  username            = "postgres"
  password            = var.db_password
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.blog.name

  vpc_security_group_ids = [aws_security_group.rds.id]
}


// output
output "rds_endpoint" {
  description = "RDS endpoint"

  value = aws_db_instance.blog.endpoint
}
