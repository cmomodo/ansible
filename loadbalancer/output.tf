output "elb_dns_name" {
  value = aws_elb.app_lb.dns_name
}

output "instance_ips" {
  value = aws_instance.app[*].public_ip
}
