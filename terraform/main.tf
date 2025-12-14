terraform {
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

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  app_name              = var.app_name
  aws_region            = var.aws_region
  vpc_cidr_block        = var.vpc_cidr_block
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"

  app_name  = var.app_name
  vpc_id    = module.vpc.vpc_id
  app_port  = var.app_port
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load_balancer"

  app_name                = var.app_name
  vpc_id                  = module.vpc.vpc_id
  app_port                = var.app_port
  alb_security_group_id   = module.security_groups.alb_security_group_id
  subnet_ids              = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
}

# Auto Scaling Module
module "auto_scaling" {
  source = "./modules/auto_scaling"

  app_name                = var.app_name
  instance_type           = var.instance_type
  app_port                = var.app_port
  ec2_security_group_id   = module.security_groups.ec2_security_group_id
  subnet_ids              = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  target_group_arn        = module.load_balancer.target_group_arn
  desired_capacity        = var.desired_capacity
  min_size                = var.min_size
  max_size                = var.max_size
  ecr_image               = var.ecr_image
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  app_name                  = var.app_name
  autoscaling_group_name    = module.auto_scaling.autoscaling_group_name
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  app_name = var.app_name
}