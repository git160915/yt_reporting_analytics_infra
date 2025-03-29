variable "bucket_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "environment" {
  description = "A prefix to apply to resource names to differentiate environments"
  type        = string
  default     = ""
}
