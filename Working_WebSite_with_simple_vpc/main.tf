# Specify the AWS provider and region
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}

# Create a subnet in us-east-1a
resource "aws_subnet" "my_subnet_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-1a"
  }
}

# Create a subnet in us-east-1c
resource "aws_subnet" "my_subnet_c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-1c"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyIGW"
  }
}

# Create a Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

# Associate Route Table with Subnet in us-east-1a
resource "aws_route_table_association" "my_route_table_association_a" {
  subnet_id      = aws_subnet.my_subnet_a.id
  route_table_id = aws_route_table.my_route_table.id
}

# Associate Route Table with Subnet in us-east-1c
resource "aws_route_table_association" "my_route_table_association_c" {
  subnet_id      = aws_subnet.my_subnet_c.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a Security Group for MySQL, HTTP, SSH, and ICMP
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "my_security_group"

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow MySQL access (port 3306)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

# Create a DB Subnet Group with subnets in us-east-1a and us-east-1c
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_c.id]

  tags = {
    Name = "MyDBSubnetGroup"
  }
}

# Create the MySQL RDS instance
resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = "password123"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  skip_final_snapshot  = true
  tags = {
    Name = "MyMySQLDB"
  }
}

# Create a Transit Gateway
resource "aws_ec2_transit_gateway" "my_tgw" {
  description = "My Transit Gateway"
  tags = {
    Name = "MyTransitGateway"
  }
}

# Attach the VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "my_tgw_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.my_tgw.id
  vpc_id             = aws_vpc.my_vpc.id
  subnet_ids         = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_c.id]

  tags = {
    Name = "MyTGWVPCAttachment"
  }
}

# Existing EC2 instance in us-east-1a
resource "aws_instance" "hello_world_instance_a" {
  ami           = "ami-06b21ccaeff8cd686" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet_a.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]  # Use security group ID

  tags = {
    Name = "HelloWorldInstance-1a"
  }

  # Use user data to install and run a simple HTTP server
  user_data = <<-EOF
              #!/bin/bash
	      sudo su -
              yum update -y
              yum install -y httpd
              "Hello, World from us-east-1c" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
	      dnf -y localinstall https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
	      dnf -y install mysql mysql-community-client
              EOF

  associate_public_ip_address = true
}

# New EC2 instance in us-east-1c
resource "aws_instance" "hello_world_instance_c" {
  ami           = "ami-06b21ccaeff8cd686" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet_c.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]  # Use security group ID

  tags = {
    Name = "HelloWorldInstance-1c"
  }

  # Use user data to install and run a simple HTTP server
  user_data = <<-EOF
              #!/bin/bash
	      sudo su -
              yum update -y
              yum install -y httpd
              "Hello, World from us-east-1c" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
	      dnf -y localinstall https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
	      dnf -y install mysql mysql-community-client
              EOF

  associate_public_ip_address = true
}

# Output the public IPs of both EC2 instances
output "ec2_public_ip_a" {
  value = aws_instance.hello_world_instance_a.public_ip
}

output "ec2_public_ip_c" {
  value = aws_instance.hello_world_instance_c.public_ip
}
