output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = [for s in aws_subnet.database : s.id]

}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

