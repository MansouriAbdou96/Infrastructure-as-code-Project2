output "VPC" {
  description = "A reference to the created VPC"
  value       = aws_vpc.VPC.id
}

output "PublicRouteTable" {
  description = "public Routing"
  value       = aws_route_table.PublicRouteTable.id
}
output "PrivateRouteT1" {
  description = "private routing AZ1"
  value       = aws_route_table.PrivateRouteT1.id
}

output "PrivateRouteT2" {
  description = "private routing AZ2"
  value       = aws_route_table.PrivateRouteT2.id
}

output "PublicSubnets" {
  description = "A list of the public subnets"
  value       = join(",", [aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id])
}

output "PrivateSubnets" {
  description = "A list of the private subnets"
  value       = join(",", [aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id])
}

output "PublicSubnet1" {
  description = "A reference to the public subnet in the 1st Availability Zone"
  value       = aws_subnet.PublicSubnet1.id
}

output "PrivateSubnet1" {
  description = "A reference to the Private subnet in the 1st Availability Zone"
  value       = aws_subnet.PrivateSubnet1.id
}

output "PublicSubnet2" {
  description = "A reference to the public subnet in the 2nd Availability Zone"
  value       = aws_subnet.PublicSubnet2.id
}

output "PrivateSubnet2" {
  description = "A reference to the private subnet in the 2nd Availability Zone"
  value       = aws_subnet.PrivateSubnet2.id
}