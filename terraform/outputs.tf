output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.load_balancer.alb_arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.auto_scaling.autoscaling_group_name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.auto_scaling.launch_template_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "app_bucket_name" {
  description = "Name of the S3 bucket for application assets"
  value       = module.s3.app_bucket_name
}

output "app_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.app_bucket_arn
}

output "log_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = module.s3.log_bucket_name
}