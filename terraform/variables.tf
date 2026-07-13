variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ubuntu_ami" {
  type    = string
  default = "ami-0b6d9d3d33ba97d99"
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}
