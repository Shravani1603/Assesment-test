variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0b6c6ebed2801a5cb"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "directus-cicd"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
