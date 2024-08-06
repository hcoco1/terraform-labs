variable "vpc_name" {
  type        = string
  default     = "vpc-tf-basics"
  description = "VPC Name tag."
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.42.0.0/16"
  description = "VPC address space."
}

variable "subnet_name" {
  type        = string
  default     = "public_subnet-1a"
  description = "Subnet Name tag."
}

variable "subnet_cidr_block" {
  type        = string
  default     = "10.42.1.0/24"
  description = "Subnet address space."
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Deployment availability zone."
}

variable "instance_name" {
  type        = string
  description = "EC2 instance name."
}

variable "instance_size" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance size."
}