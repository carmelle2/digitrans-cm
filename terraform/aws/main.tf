terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "digitrans-cm-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "af-south-1"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "DIGITRANS-CM"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Client      = "AGROCAM-SA"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS Region (Cape Town for data sovereignty)"
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "digitrans-cm-vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "digitrans-cm-igw-${var.environment}"
  }
}

# Public Subnets (2 AZs for high availability)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "digitrans-cm-public-1-${var.environment}"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "digitrans-cm-public-2-${var.environment}"
    Tier = "Public"
  }
}

# Private Subnets (for databases and backend services)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "digitrans-cm-private-1-${var.environment}"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "digitrans-cm-private-2-${var.environment}"
    Tier = "Private"
  }
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "digitrans-cm-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "digitrans-cm-nat-${var.environment}"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "digitrans-cm-public-rt-${var.environment}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "digitrans-cm-private-rt-${var.environment}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "digitrans-cm-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere (redirect to HTTPS)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "digitrans-cm-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "app" {
  name        = "digitrans-cm-app-sg-${var.environment}"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8084
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "digitrans-cm-app-sg-${var.environment}"
  }
}

resource "aws_security_group" "rds" {
  name        = "digitrans-cm-rds-sg-${var.environment}"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "MySQL from app servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "digitrans-cm-rds-sg-${var.environment}"
  }
}

resource "aws_security_group" "redis" {
  name        = "digitrans-cm-redis-sg-${var.environment}"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Redis from app servers"
  }

  tags = {
    Name = "digitrans-cm-redis-sg-${var.environment}"
  }
}

# RDS MySQL Instances (4 databases for ERP, CRM, Supply, BI)
resource "aws_db_subnet_group" "main" {
  name       = "digitrans-cm-db-subnet-${var.environment}"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "digitrans-cm-db-subnet-${var.environment}"
  }
}

resource "aws_db_instance" "erp" {
  identifier             = "digitrans-cm-erp-${var.environment}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "erp_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.environment == "prod" ? true : false
  backup_retention_period = 7
  skip_final_snapshot    = var.environment != "prod"
  publicly_accessible    = false

  tags = {
    Name = "digitrans-cm-erp-db-${var.environment}"
  }
}

resource "aws_db_instance" "crm" {
  identifier             = "digitrans-cm-crm-${var.environment}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "crm_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.environment == "prod" ? true : false
  backup_retention_period = 7
  skip_final_snapshot    = var.environment != "prod"
  publicly_accessible    = false

  tags = {
    Name = "digitrans-cm-crm-db-${var.environment}"
  }
}

resource "aws_db_instance" "supply" {
  identifier             = "digitrans-cm-supply-${var.environment}"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "supply_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.environment == "prod" ? true : false
  backup_retention_period = 7
  skip_final_snapshot    = var.environment != "prod"
  publicly_accessible    = false

  tags = {
    Name = "digitrans-cm-supply-db-${var.environment}"
  }
}

# ElastiCache Redis for offline-first caching
resource "aws_elasticache_subnet_group" "main" {
  name       = "digitrans-cm-redis-subnet-${var.environment}"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "digitrans-cm-redis-${var.environment}"
  replication_group_description = "Redis cluster for offline-first caching"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = var.environment == "prod" ? "cache.t3.medium" : "cache.t3.micro"
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name = "digitrans-cm-redis-${var.environment}"
  }
}

# S3 Bucket for application assets and backups
resource "aws_s3_bucket" "assets" {
  bucket = "digitrans-cm-assets-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "digitrans-cm-assets-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "digitrans-cm-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "digitrans-cm-alb-${var.environment}"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "rds_erp_endpoint" {
  value     = aws_db_instance.erp.endpoint
  sensitive = true
}

output "rds_crm_endpoint" {
  value     = aws_db_instance.crm.endpoint
  sensitive = true
}

output "rds_supply_endpoint" {
  value     = aws_db_instance.supply.endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.assets.id
}
