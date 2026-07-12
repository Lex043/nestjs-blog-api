// default aws vpc
data "aws_vpc" "default" {
  default = true
}

// key pair
resource "aws_key_pair" "blog" {
  key_name   = "blog-key"
  public_key = file("~/.ssh/blog-key.pub")
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
  cidr_ipv4         = "105.119.42.118/32"
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
