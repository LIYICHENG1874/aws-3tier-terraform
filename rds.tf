resource "aws_db_subnet_group" "db_subnet_group_isolated" {
  name = "db-subnet-group-isolated"

  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_c.id
  ]

  tags = {
    Name = "db-subnet-group-isolated"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "demo-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group_isolated.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  multi_az            = false

  skip_final_snapshot = true

  tags = {
      Name = "${var.project_name}-mysql"
  }
}
