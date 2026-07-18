// default aws vpc
data "aws_vpc" "default" {
  default = true
}

// key pair
resource "aws_key_pair" "blog" {
  key_name   = "blog-key"
  public_key = file("${path.module}/keys/blog-key.pub")
}

// terraform state bucket
terraform {
  backend "s3" {
    bucket = "lex-blog-api-tfstate"
    key    = "blog-api/terraform.tfstate"
    region = "us-east-1"
  }
}

// iam role for ssm
resource "aws_iam_role" "ec2_ssm" {
  name = "ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "ec2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}


// security group to allow port 22, 80
resource "aws_security_group" "ec2" {
  name        = "blog-api-sg"
  description = "Security group for Nestjs Blog API"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "blog-api-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  description       = "SSH"
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "105.119.5.177/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
  description       = "HTTP"
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# resource "aws_vpc_security_group_ingress_rule" "ec2_3000" {
#   description       = "NestJS"
#   security_group_id = aws_security_group.ec2.id
#   cidr_ipv4         = "0.0.0.0/0"

#   from_port   = 3000
#   to_port     = 3000
#   ip_protocol = "tcp"
# }

resource "aws_vpc_security_group_ingress_rule" "ec2_8080" {
  description       = "Traefik Dashboard"
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "105.119.41.23/32"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
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

  referenced_security_group_id = aws_security_group.ec2.id
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

// ec2 instance
resource "aws_instance" "blog_api" {
  ami           = var.ubuntu_ami
  instance_type = "t3.micro"

  key_name = aws_key_pair.blog.key_name

  subnet_id = data.aws_subnets.default.ids[0]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  tags = {
    Name = "nestjs-blog-api"
  }
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
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"

  value = aws_instance.blog_api.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"

  value = aws_db_instance.blog.endpoint
}
