provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

resource "aws_route53_record" "squash-www" {
  zone_id = "${var.aws_zone_id}"
  name    = "${var.service_name}.${var.namespace_name}.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = ["${var.external_ip}"]
}
