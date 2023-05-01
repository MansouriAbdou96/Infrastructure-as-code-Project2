
output "LBUrl" {
  description = "URL of the Load Balancer"
  value       = join("", ["http://", aws_lb.WebAppLB.dns_name])
}