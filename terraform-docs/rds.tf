# 1. Create a Security Group for the Database
resource "aws_security_group" "rds_sg" {
  name        = "cloudmart-rds-sg"
  description = "Allow traffic from EC2 to RDS"
  vpc_id      = aws_vpc.cloudmart_vpc.id # Matched to your main.tf

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Matched to your web_sg
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Create the RDS Instance
resource "aws_db_instance" "cloudmart_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "cloudmart"
  username             = "admin"
  password             = "cloudmart_password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
}

# 3. Create a Subnet Group (Using your subnets from two different zones)
resource "aws_db_subnet_group" "main" {
  name       = "cloudmart-db-subnet-group"
  # We use the subnet from 1a and the new one from 1b
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id] 

  tags = {
    Name = "CloudMart DB Subnet Group"
  }
}
output "rds_endpoint" {
  value = aws_db_instance.cloudmart_db.endpoint
  description = "The connection endpoint for the RDS database"
}
