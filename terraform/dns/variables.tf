variable "aws_access_key" {
  description = "AWS access key id."
}

variable "aws_secret_key" {
  description = "AWS secret access key."
}

variable "aws_zone_id" {
  description = "route53 Hosted Zone ID to manage DNS records in."
  default     = "Z3TH0HRSNU67AM"
}

variable "service_name" {
  description = "Name of the service for which the DNS record is being created."
}

variable "namespace_name" {
  description = "Kubernetes namespace, used to configure the resource name."
}

variable "domain_name" {
  description = "DNS domain name to use when creating route53 records."
  default     = "lsst.codes"
}

variable "external_ip" {
  description = "External IP from the k8s squash service"
}
