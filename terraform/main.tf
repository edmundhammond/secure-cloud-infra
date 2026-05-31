terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Secure Multi-Tier VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Secure-Prod-VPC"
    Environment = "Production"
  }
}

# Public Subnet (For Load Balancer)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "Prod-Public-Subnet" }
}

# Private Subnet (For Apps/Databases)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "Prod-Private-Subnet" }
}

# FIXED: Secure S3 Bucket with Encryption and Public Access Blocks
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "devsecops-demo-bucket-unencrypted-2026"

  tags = {
    Name = "Secure-Demo-Bucket"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "insecure_bucket_versioning" {
  bucket = aws_s3_bucket.insecure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "insecure_bucket_encryption" {
  bucket = aws_s3_bucket.insecure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "insecure_bucket_pab" {
  bucket = aws_s3_bucket.insecure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "insecure_bucket_logging" {
  bucket = aws_s3_bucket.insecure_bucket.id

  target_bucket = aws_s3_bucket.insecure_bucket.id
  target_prefix = "logs/"
}