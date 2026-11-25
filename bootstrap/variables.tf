variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Globally unique state bucket name"
  type        = string
}
